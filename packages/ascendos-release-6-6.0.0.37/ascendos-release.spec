%define debug_package %{nil}
%define product_family Ascendos
%define release_name Nameless
%define base_release_version 6
%define full_release_version 6.0

Name:           ascendos-release%{?variant_lowercase:-%{variant_lowercase}}
Version:        6
Release:        6.0.0.37%{?dist}.asc.3
Summary:        %{product_family}%{?variant_titlecase: %{variant_titlecase}} release file
Group:          System Environment/Base
License:        GPLv2
Obsoletes:      rawhide-release redhat-release-as redhat-release-es redhat-release-ws redhat-release-de comps rpmdb-redhat fedora-release
Provides:       redhat-release system-release
Source0:        ascendos-release%{?variant_lowercase:-%{variant_lowercase}}-%{full_release_version}.tar.gz

%description
%{product_family}%{?variant_titlecase: %{variant_titlecase}} release files

%prep
%setup -q -n ascendos-release%{?variant_lowercase:-%{variant_lowercase}}-%{full_release_version}

%build
echo OK

%install
rm -rf $RPM_BUILD_ROOT

# create /etc
mkdir -p $RPM_BUILD_ROOT/etc

# create /etc/{system,ascendos,redhat}-release
echo "%{product_family}%{?variant_titlecase: %{variant_titlecase}} release %{full_release_version}%{?beta: %{beta}} (%{release_name})" > $RPM_BUILD_ROOT/etc/ascendos-release
cp $RPM_BUILD_ROOT/etc/ascendos-release $RPM_BUILD_ROOT/etc/redhat-release
ln -s redhat-release $RPM_BUILD_ROOT/etc/system-release

# write cpe to /etc/system/release-cpe
echo "cpe:/o:redhat:enterprise_linux:%{version}:%{?beta:beta}%{!?beta:GA}%{?variant_lowercase::%{variant_lowercase}}" | tr [A-Z] [a-z] > $RPM_BUILD_ROOT/etc/system-release-cpe

# create /etc/issue and /etc/issue.net
cp $RPM_BUILD_ROOT/etc/ascendos-release $RPM_BUILD_ROOT/etc/issue
echo "Kernel \r on an \m" >> $RPM_BUILD_ROOT/etc/issue
cp $RPM_BUILD_ROOT/etc/issue $RPM_BUILD_ROOT/etc/issue.net
echo >> $RPM_BUILD_ROOT/etc/issue

# copy yum repos to /etc/yum.repos.d
mkdir -p $RPM_BUILD_ROOT/etc/yum.repos.d
for file in *.repo; do
    install -m 644 $file $RPM_BUILD_ROOT/etc/yum.repos.d
done

# Combine GPG keys
cat RPM-GPG-KEY-redhat-release-2 RPM-GPG-KEY-redhat-auxiliary > RPM-GPG-KEY-redhat-release
rm RPM-GPG-KEY-redhat-release-2 RPM-GPG-KEY-redhat-auxiliary
cat RPM-GPG-KEY-redhat-beta-2 RPM-GPG-KEY-redhat-legacy-beta > RPM-GPG-KEY-redhat-beta
rm RPM-GPG-KEY-redhat-beta-2 RPM-GPG-KEY-redhat-legacy-beta

# copy GPG keys
mkdir -p -m 755 $RPM_BUILD_ROOT/etc/pki/rpm-gpg
for file in RPM-GPG-KEY* ; do
    install -m 644 $file $RPM_BUILD_ROOT/etc/pki/rpm-gpg
done

# set up the dist tag macros
install -d -m 755 $RPM_BUILD_ROOT/etc/rpm
cat >> $RPM_BUILD_ROOT/etc/rpm/macros.dist << EOF
# dist macros.

%%rhel %{base_release_version}
%%dist .el%{base_release_version}
%%el%{base_release_version} 1
EOF

%clean
rm -rf $RPM_BUILD_ROOT

%triggerin -- firstboot
if [ -f /usr/share/firstboot/modules/additional_cds.py ] ; then
  rm -f /usr/share/firstboot/modules/additional_cds.py*
fi
if [ -f /usr/share/firstboot/modules/eula.py ] ; then
  rm -f /usr/share/firstboot/modules/eula.py*
fi
%triggerin -- rhn-setup-gnome
if [ -f /usr/share/firstboot/modules/rhn_register.py ] ; then
  rm -f /usr/share/firstboot/modules/rhn_register.py*
fi

%files
%defattr(-,root,root)
%doc GPL autorun-template
%attr(0644,root,root) /etc/ascendos-release
%attr(0644,root,root) /etc/redhat-release
/etc/system-release
%config %attr(0644,root,root) /etc/system-release-cpe
%config(noreplace) %attr(0644,root,root) /etc/issue
%config(noreplace) %attr(0644,root,root) /etc/issue.net
%config %attr(0644,root,root) /etc/yum.repos.d/*
%dir /etc/pki/rpm-gpg
/etc/pki/rpm-gpg/*
/etc/rpm/macros.dist

%changelog
* Fri Oct 14 2011 Douglas McClendon <dmc@ascendos.org> - 6-6.0.0.37.asc.3
- update .repo files with temporary mirrorlist only configuration

* Thu Oct 06 2011 Douglas McClendon <dmc@ascendos.org> - 6-6.0.0.37.asc.2
- update ascendos.repo, add ascendos-updates.repo (alpha first pass)
- added RPM-GPG-KEY-ascendos-alpha-dmc
- create /etc/ascendos-release in addition to others
- fixed date on prior changelog

* Thu Sep 29 2011 Douglas McClendon <dmc@ascendos.org> - 6-6.0.0.37.asc.1
- cleaned up ascendos.repo, added mirrorlist and mirror entries

* Sat Jul 30 2011 Troy Dawson <dawson@ascendos.rog> 
- Changed everything to ascendos release
- Added triggers to remove redhat specific firstboot modules

* Fri Sep  3 2010 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.37
- Update EULA
- Resolves: rhbz#591512

* Tue Aug 31 2010 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.36
- Remove beta text
- Update EULA
- Resolves: rhbz#622251, rhbz#591512

* Mon Aug 16 2010 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.35
- Bump for GA
- Resolves: rhbz#622251

* Mon Jul 26 2010 Dennis Gregorovic <dgregor@redhat.com> - 5.91-6.0.0.34
- Update yum repos for GA

* Tue Jun 29 2010 Dennis Gregorovic <dgregor@redhat.com> - 5.91-6.0.0.33
- Update GPL to match standard text

* Tue Jun 29 2010 Dennis Gregorovic <dgregor@redhat.com> - 5.91-6.0.0.32
- Bump version for post-Beta2

* Wed Jun 16 2010 Dennis Gregorovic <dgregor@redhat.com> - 5.90-6.0.0.32
- Fix logic for AddOn repos

* Tue Jun 15 2010 Dennis Gregorovic <dgregor@redhat.com> - 5.90-6.0.0.31
- Only include the AddOn repos in the appropriate arches/variants
- Update the Beta GPG key locations
- Resolves: rhbz#603701, rhbz600288

* Tue Jun  8 2010 Dennis Gregorovic <dgregor@redhat.com> - 5.90-6.0.0.29
- Combine GPG keys
- Resolves: rhbz#600287, rhbz#600288

* Fri May 28 2010 Dennis Gregorovic <dgregor@redhat.com> - 5.90-6.0.0.28
- Use a different version value so as to not conflict with GA

* Fri May 28 2010 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.28
- Include the variant in the version field (needed for RHN)
- Update repos for Beta 2
- Resolves: rhbz#594504

* Mon Apr 26 2010 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.27
- Make 'Beta' lowercase in the cpe
- Provide system-release
- Resolves: rhbz#577167 rhbz#578199

* Wed Mar 31 2010 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.25
- Temporarily disable beta repos
- Reverts: rhbz#572308

* Mon Mar 29 2010 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.24
- Add beta debuginfo repos
- Resolves: rhbz#572308

* Mon Mar 29 2010 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.23
- Enable yum repo for Beta

* Wed Mar 10 2010 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.21
- Update yum repos for Beta 1

* Fri Feb  5 2010 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.20
- Use the %{?dist} macro
- Related: rhbz#561120

* Wed Feb  3 2010 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.19
- Mark the yum repos as configuration files
- Resolves: rhbz#561277

* Tue Feb  2 2010 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.18
- Use %setup -q to keeep rpmlint happy
- Resolves: rhbz#561120

* Thu Jan 28 2010 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.17
- Bump for Beta
- Related: rhbz#559610

* Tue Nov 17 2009 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.16
- Fix newline issue in RPM-GPG-KEY-redhat-beta-2
- spec file cleanup
- Resolves: rhbz#532992

* Thu Oct  22 2009 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.15
- Spec cleanup (dmach@redhat.com)
- Add the beta-2 and release-2 keys
- Rename the older keys
- Comment out eula.py code until it gets cleaned up
- Resolves: rhbz#530347
- Related: rhbz#526951

* Mon Sep 21 2009 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.14
- Fix typo in cpe name
- Resolves: rhbz#404371

* Fri Sep 18 2009 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.13
- Fix the cpe name
- Resolves: rhbz#404371

* Thu Sep 17 2009 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.12
- Update the release name

* Thu Sep 17 2009 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.11
- Add system-release-cpe
- Resolves: rhbz#404371

* Tue Sep 15 2009 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.10
- Add the 'el6' macro
- Resolves: rhbz#513075

* Tue Sep  1 2009 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.9
- Bump for rebuild

* Tue Aug 11 2009 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.8
- Indicate Alpha instead of Beta
- Resolves: rhbz#513290

* Wed Jun 24 2009 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.7
- Updated eula.py
- Resolves: rhbz#507426

* Tue Jun 23 2009 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.6
- Add eula.py back
- Resolves: rhbz#507426

* Mon Jun 15 2009 Dennis Gregorovic <dgregor@redhat.com> - 6-6.0.0.5
- add /etc/system-release
- some minor cleanup

* Fri Jun  5 2009 Dennis Gregorovic <dgregor@redhat.com> - 6Server-6.0.0.4
- bump for rebuild

* Fri Jun  5 2009 Dennis Gregorovic <dgregor@redhat.com> - 6Server-6.0.0.3
- Drop firstboot files as they conflict with the firstboot package

* Wed Jun  3 2009 Mike McLean <mikem@redhat.com> - 6Server-6.0.0.1
- initial build for version 6
