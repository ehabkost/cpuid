Summary: dumps CPUID information about the CPU(s)
Name: cpuid
Version: %{version}
Release: %{release}
Copyright: BSD
Group: System Environment/Base
Source: cpuid-%{version}.src.tar.gz
Packager: Todd Allen <todd.allen@etoddallen.com>
URL: http://www.etallen.com
%description
cpuid dumps detailed information about the CPU(s) gathered from the CPUID 
instruction, and also determines the exact model of CPU(s).

%prep
%setup

%build
make

%install
install -D -s -m 755 -o 0 -g 0 cpuid     %{buildroot}/usr/bin/cpuid
install -D    -m 444 -o 0 -g 0 cpuid.man %{buildroot}/usr/share/man/man1/cpuid.1

%clean
rm -rf $RPM_BUILD_DIR/$RPM_PACKAGE_NAME-$RPM_PACKAGE_VERSION

%files
/usr/bin/cpuid
/usr/share/man/man1/cpuid.1.gz
