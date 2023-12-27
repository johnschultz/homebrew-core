class Nmap < Formula
  desc "Port scanning utility for large networks"
  homepage "https://nmap.org/"
  license :cannot_represent
  revision 1
  head "https://svn.nmap.org/nmap/"

  # TODO: Remove stable block in next release.
  stable do
    url "https://nmap.org/dist/nmap-7.94.tar.bz2"
    sha256 "d71be189eec43d7e099bac8571509d316c4577ca79491832ac3e1217bc8f92cc"

    # Fix build with Lua 5.4. Remove in next release.
    patch do
      url "https://github.com/nmap/nmap/commit/b9263f056ab3acd666d25af84d399410560d48ac.patch?full_index=1"
      sha256 "088d426dc168b78ee4e0450d6b357deef13e0e896b8988164ba2bb8fd8b8767c"
    end

    # Backport pcre2 support. Remove in next release.
    patch :DATA # https://github.com/nmap/nmap/commit/85f38cb858065d4b0e384730258494e8639887db
    patch do
      url "https://github.com/nmap/nmap/commit/828ab48764b82d0226e860c73c5dac5b11f77385.patch?full_index=1"
      sha256 "3b5febc6c10acc59bff1c43e252d221b9c9be0cd4d866294f91f40a5d008eff0"
    end
    patch do
      url "https://github.com/nmap/nmap/commit/d131a096a869195be36ef7d4fa36739373346cb2.patch?full_index=1"
      sha256 "5acbcae9f3ef33b9fe38005c0b3c0df4154fb2ae6e0bc38a915f45d473f71c66"
    end
  end

  livecheck do
    url "https://nmap.org/dist/"
    regex(/href=.*?nmap[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    rebuild 2
    sha256 arm64_sonoma:   "a2e968804393cf5dadff37cdf5c9fa3e6a1b0c1454ed93ed54807e76cb95072a"
    sha256 arm64_ventura:  "aa642e107f9b1fb16d729c695610cc8aa6812d67c3509f3fb5d1edb1a34dfa00"
    sha256 arm64_monterey: "6a5c8706843e47e4f7628ae22f8c944ff64a597e11bea98b1c098551d33d10a1"
    sha256 arm64_big_sur:  "afde313363e967039eea3c63362dfe38b30372a24283a19fb8fd5db254e722c4"
    sha256 sonoma:         "525e002a6320e185cc4fa1d34b80d3e6988d171e0b856fa801df23d70f204d3e"
    sha256 ventura:        "631de555fe12ba7e1bd5ab64bffa7230b1a199be1ceb2f4f55b41e86447a9f65"
    sha256 monterey:       "9b434cc856194b8ea128ddd9ef20a5aa4e2bad768d6332a68a9daef7a5d95236"
    sha256 big_sur:        "62a6dfc9eb7b925bd2cbeb65be00f80f59ba109351ff70215cb5b652c92f32e7"
    sha256 x86_64_linux:   "118dd698850f64fb06e40ac242dc5f88b921871f60b0306ffad253c78ca49e5a"
  end

  depends_on "liblinear"
  depends_on "libssh2"
  # Check supported Lua version at https://github.com/nmap/nmap/tree/master/liblua.
  depends_on "lua"
  depends_on "openssl@3"
  depends_on "pcre2"

  uses_from_macos "bison" => :build
  uses_from_macos "flex" => :build
  uses_from_macos "libpcap"
  uses_from_macos "zlib"

  conflicts_with "cern-ndiff", "ndiff", because: "both install `ndiff` binaries"

  def install
    ENV.deparallelize

    libpcap_path = if OS.mac?
      MacOS.sdk_path/"usr/"
    else
      Formula["libpcap"].opt_prefix
    end

    args = %W[
      --with-liblua=#{Formula["lua"].opt_prefix}
      --with-libpcre=#{Formula["pcre2"].opt_prefix}
      --with-openssl=#{Formula["openssl@3"].opt_prefix}
      --with-libpcap=#{libpcap_path}
      --without-nmap-update
      --disable-universal
      --without-zenmap
    ]

    system "./configure", *args, *std_configure_args
    system "make" # separate steps required otherwise the build fails
    system "make", "install"

    bin.glob("uninstall_*").map(&:unlink) # Users should use brew uninstall.
    return unless (bin/"ndiff").exist? # Needs Python

    # We can't use `rewrite_shebang` here because `detected_python_shebang` only works
    # for shebangs that start with `/usr/bin`, but the shebang we want to replace
    # might start with `/Applications` (for the `python3` inside Xcode.app).
    inreplace bin/"ndiff", %r{\A#!.*/python(\d+(\.\d+)?)?$}, "#!/usr/bin/env python3"
  end

  def caveats
    on_macos do
      <<~EOS
        If using `ndiff` returns an error about not being able to import the ndiff module, try:
          chmod go-w #{HOMEBREW_CELLAR}
      EOS
    end
  end

  test do
    system bin/"nmap", "-p80,443", "google.com"
  end
end

__END__
diff --git a/configure b/configure
index d1d2f19e0d..30a455492e 100755
--- a/configure
+++ b/configure
@@ -754,7 +754,6 @@ infodir
 docdir
 oldincludedir
 includedir
-runstatedir
 localstatedir
 sharedstatedir
 sysconfdir
@@ -853,7 +852,6 @@ datadir='${datarootdir}'
 sysconfdir='${prefix}/etc'
 sharedstatedir='${prefix}/com'
 localstatedir='${prefix}/var'
-runstatedir='${localstatedir}/run'
 includedir='${prefix}/include'
 oldincludedir='/usr/include'
 docdir='${datarootdir}/doc/${PACKAGE}'
@@ -1106,15 +1104,6 @@ do
   | -silent | --silent | --silen | --sile | --sil)
     silent=yes ;;
 
-  -runstatedir | --runstatedir | --runstatedi | --runstated \
-  | --runstate | --runstat | --runsta | --runst | --runs \
-  | --run | --ru | --r)
-    ac_prev=runstatedir ;;
-  -runstatedir=* | --runstatedir=* | --runstatedi=* | --runstated=* \
-  | --runstate=* | --runstat=* | --runsta=* | --runst=* | --runs=* \
-  | --run=* | --ru=* | --r=*)
-    runstatedir=$ac_optarg ;;
-
   -sbindir | --sbindir | --sbindi | --sbind | --sbin | --sbi | --sb)
     ac_prev=sbindir ;;
   -sbindir=* | --sbindir=* | --sbindi=* | --sbind=* | --sbin=* \
@@ -1252,7 +1241,7 @@ fi
 for ac_var in	exec_prefix prefix bindir sbindir libexecdir datarootdir \
 		datadir sysconfdir sharedstatedir localstatedir includedir \
 		oldincludedir docdir infodir htmldir dvidir pdfdir psdir \
-		libdir localedir mandir runstatedir
+		libdir localedir mandir
 do
   eval ac_val=\$$ac_var
   # Remove trailing slashes.
@@ -1405,7 +1394,6 @@ Fine tuning of the installation directories:
   --sysconfdir=DIR        read-only single-machine data [PREFIX/etc]
   --sharedstatedir=DIR    modifiable architecture-independent data [PREFIX/com]
   --localstatedir=DIR     modifiable single-machine data [PREFIX/var]
-  --runstatedir=DIR       modifiable per-process data [LOCALSTATEDIR/run]
   --libdir=DIR            object code libraries [EPREFIX/lib]
   --includedir=DIR        C header files [PREFIX/include]
   --oldincludedir=DIR     C header files for non-gcc [/usr/include]
