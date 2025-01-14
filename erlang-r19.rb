class ErlangR19 < Formula
  desc "Erlang Programming Language"
  homepage "http://www.erlang.org"
  url "https://github.com/erlang/otp/archive/OTP-19.0.2.tar.gz"
  sha256 "d0ec363d460994e63ef984c2367598990978ffe1d41bb0e0c25520a0ee1dab21"

  bottle do
    cellar :any
    sha256 "d1e97e4f15814dfae9ec8d4aa768452c63783049ea9a37e03514ef16d1ec721c" => :el_capitan
    sha256 "d899e7d9154ff58a20ade8f511d0aab2a16ab171127cc24d401bd68739754eb7" => :yosemite
    sha256 "d7e578457c8a9544db0ac16beaa4973b549e6dbb79b0a70083acf18c1fd80cc0" => :mavericks
  end

  option "without-hipe", "Disable building hipe; fails on various OS X systems"
  option "with-native-libs", "Enable native library compilation"
  option "with-dirty-schedulers", "Enable experimental dirty schedulers"
  option "without-docs", "Do not install documentation"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "openssl"
  depends_on "unixodbc" if MacOS.version >= :mavericks
  depends_on "fop" => :optional # enables building PDF docs
  depends_on "wxmac" => :optional # for GUI apps like observer

  resource "man" do
    url "http://www.erlang.org/download/otp_doc_man_19.0.tar.gz"
    sha256 "c7a3d6d85a5a2b96d844297a3fa1bee448c3dd86237734688466249fd5a1401e"
  end

  resource "html" do
    url "http://www.erlang.org/download/otp_doc_html_19.0.tar.gz"
    sha256 "b6f7c4e964673333f6c3eea8530dd988b41339b8912ae293f6f1b429489159ff"
  end

  conflicts_with "erlang", :because => "Different version of same formula"

  fails_with :llvm

  def install
    # Unset these so that building wx, kernel, compiler and
    # other modules doesn't fail with an unintelligable error.
    %w[LIBS FLAGS AFLAGS ZFLAGS].each { |k| ENV.delete("ERL_#{k}") }

    ENV["FOP"] = "#{HOMEBREW_PREFIX}/bin/fop" if build.with? "fop"

    # Do this if building from a checkout to generate configure
    system "./otp_build", "autoconf" if File.exist? "otp_build"

    args = %W[
      --disable-debug
      --disable-silent-rules
      --prefix=#{prefix}
      --enable-kernel-poll
      --enable-threads
      --enable-sctp
      --enable-dynamic-ssl-lib
      --with-ssl=#{Formula["openssl"].opt_prefix}
      --enable-shared-zlib
      --enable-smp-support
    ]

    args << "--enable-darwin-64bit" if MacOS.prefer_64_bit?
    args << "--enable-native-libs" if build.with? "native-libs"
    args << "--enable-dirty-schedulers" if build.with? "dirty-schedulers"
    args << "--enable-wx" if build.with? "wxmac"

    if MacOS.version >= :snow_leopard && MacOS::CLT.installed?
      args << "--with-dynamic-trace=dtrace"
    end

    if build.without? "hipe"
      # HIPE doesn't strike me as that reliable on OS X
      # http://syntatic.wordpress.com/2008/06/12/macports-erlang-bus-error-due-to-mac-os-x-1053-update/
      # http://www.erlang.org/pipermail/erlang-patches/2008-September/000293.html
      args << "--disable-hipe"
    else
      args << "--enable-hipe"
    end

    system "./configure", *args
    system "make"
    ENV.j1 # Install is not thread-safe; can try to create folder twice and fail
    system "make", "install"

    if build.with? "docs"
      (lib/"erlang").install resource("man").files("man")
      doc.install resource("html")
    end
  end

  def caveats; <<-EOS.undent
    Man pages can be found in:
      #{opt_lib}/erlang/man

    Access them with `erl -man`, or add this directory to MANPATH.
    EOS
  end

  test do
    system "#{bin}/erl", "-noshell", "-eval", "crypto:start().", "-s", "init", "stop"
  end
end
