# Copyright 2024 Wong Hoi Sing Edison <hswong3i@pantarei-design.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

%global debug_package %{nil}

%global source_date_epoch_from_changelog 0

Name: passt
Epoch: 100
Version: 0.0+20240326.4988e2b4
Release: 1%{?dist}
Summary: User-mode networking daemons for virtual machines and namespaces
License: BSD-3-Clause
URL: https://passt.top/passt/refs/tags
Source0: %{name}_%{version}.orig.tar.gz
%if 0%{?rhel} == 7
BuildRequires: devtoolset-11
BuildRequires: devtoolset-11-gcc
BuildRequires: devtoolset-11-gcc-c++
BuildRequires: devtoolset-11-libatomic-devel
%endif
%if !(0%{?sle_version} > 15000)
BuildRequires: selinux-policy-devel
%endif
BuildRequires: checkpolicy
BuildRequires: gcc
BuildRequires: glibc-static
BuildRequires: libtool
BuildRequires: make
BuildRequires: pkgconfig

%description
passt implements a translation layer between a Layer-2 network interface
and native Layer-4 sockets (TCP, UDP, ICMP/ICMPv6 echo) on a host. It
doesn't require any capabilities or privileges, and it can be used as a
simple replacement for Slirp.

pasta (same binary as passt, different command) offers equivalent
functionality, for network namespaces: traffic is forwarded using a tap
interface inside the namespace, without the need to create further
interfaces on the host, hence not requiring any capabilities or

%prep
%autosetup -T -c -n %{name}_%{version}-%{release}
tar -zx -f %{S:0} --strip-components=1 -C .

%build
%if 0%{?rhel} == 7
. /opt/rh/devtoolset-11/enable
%endif
%set_build_flags
%make_build static \
    VERSION=%{version}

%install
%make_install \
    DESTDIR=%{buildroot} \
    prefix=%{_prefix} \
    bindir=%{_bindir} \
    docdir=%{_docdir}/passt
ln -sr %{buildroot}%{_mandir}/man1/passt.1 %{buildroot}%{_mandir}/man1/passt.avx2.1
ln -sr %{buildroot}%{_mandir}/man1/pasta.1 %{buildroot}%{_mandir}/man1/pasta.avx2.1

%if !(0%{?sle_version} > 15000)
pushd contrib/selinux
make -f %{_datadir}/selinux/devel/Makefile
install -p -m 644 -D passt.pp %{buildroot}%{_datadir}/selinux/packages/passt/passt.pp
install -p -m 644 -D pasta.pp %{buildroot}%{_datadir}/selinux/packages/passt/pasta.pp
popd

%post
semodule -i %{_datadir}/selinux/packages/passt/passt.pp 2>/dev/null || :
semodule -i %{_datadir}/selinux/packages/passt/pasta.pp 2>/dev/null || :

%preun
semodule -r passt 2>/dev/null || :
semodule -r pasta 2>/dev/null || :
%endif

%files
%if !(0%{?sle_version} > 15000)
%dir %{_datadir}/selinux/packages/passt
%{_datadir}/selinux/packages/passt/*
%endif
%license LICENSES/BSD-3-Clause.txt
%dir %{_docdir}/passt
%{_bindir}/*
%{_docdir}/passt/*
%{_mandir}/*/*

%changelog
