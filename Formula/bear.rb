class Bear < Formula
  desc "Generate compilation database for clang tooling"
  homepage "https://github.com/rizsotto/Bear"
  url "https://github.com/rizsotto/Bear/archive/2.3.13.tar.gz"
  sha256 "dc14c28bfbe0beef5ec93b4614a00bd419d5a793c8a678ba3b5544bd1dd580b6"
  head "https://github.com/rizsotto/Bear.git"

  bottle do
    cellar :any
    sha256 "a569b9ebe198df8e6c2b505e3ad6739b577cc0aaf53c5f47686b9a7df3e6e5ed" => :mojave
    sha256 "5afbef9c21e06bfac32e075ab932d012cf9a7ea54fd4b277f2968d96b59b6e56" => :high_sierra
    sha256 "8164fb4aaa557d17d786f0bcbc516b96a80a3b962215c1343e72f1496564a566" => :sierra
    sha256 "96e86ed2419baca6c3ac3a899c0c75ea5f5afba62b8c08c2fc975fc257ec04e1" => :el_capitan
  end

  depends_on "cmake" => :build
  depends_on "python@2"

  def install
    system "cmake", ".", *std_cmake_args
    system "make", "install"
  end

  test do
    system "#{bin}/bear", "true"
    assert_predicate testpath/"compile_commands.json", :exist?
  end
end
