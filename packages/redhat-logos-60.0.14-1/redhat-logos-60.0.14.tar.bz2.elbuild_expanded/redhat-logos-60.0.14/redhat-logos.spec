# Anaconda looks here for images
%define anaconda_image_prefix /usr/lib/anaconda-runtime

Name: redhat-logos
Summary: Ascendos logos and artwork. 
Version: 60.0.14
Release: 1.asc6
Group: System Environment/Base
# No upstream, do in dist-cvs
Source0: redhat-logos-%{version}.tar.bz2

License: GPL+, CC-BY-SA
URL: http://ascendos.org/
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch: noarch
Conflicts: anaconda-images <= 10
Provides: system-logos = %{version}-%{release}
Obsoletes: desktop-backgrounds-basic <= 60.0.1-1.el6
Provides: desktop-backgrounds-basic = %{version}-%{release}
Conflicts: redhat-artwork <= 5.0.5
Requires(post): coreutils
# For _kde4_appsdir macro:
BuildRequires: kde-filesystem

%description
Ascendos artwork and branding elements

%prep
%setup -q

%build

%install
rm -rf $RPM_BUILD_ROOT

##Shamelessly copied and pasted from upstream
# should be ifarch i386
mkdir -p $RPM_BUILD_ROOT/boot/grub
install -p -m 644 -D bootloader/splash.xpm.gz $RPM_BUILD_ROOT/boot/grub/splash.xpm.gz
# end i386 bits

mkdir -p $RPM_BUILD_ROOT%{_datadir}/pixmaps/redhat
for i in redhat-pixmaps/*; do
  install -p -m 644 $i $RPM_BUILD_ROOT%{_datadir}/pixmaps/redhat
done

mkdir -p $RPM_BUILD_ROOT%{_datadir}/backgrounds/
for i in backgrounds/*.png backgrounds/tuv.xml backgrounds/default.xml; do
  install -p -m 644 $i $RPM_BUILD_ROOT%{_datadir}/backgrounds/
done

mkdir -p $RPM_BUILD_ROOT%{_datadir}/gnome-background-properties/
install -p -m 644 backgrounds/desktop-backgrounds-default.xml $RPM_BUILD_ROOT%{_datadir}/gnome-background-properties/
install -p -m 644 backgrounds/desktop-backgrounds-tuv.xml $RPM_BUILD_ROOT%{_datadir}/gnome-background-properties/

mkdir -p $RPM_BUILD_ROOT%{_datadir}/firstboot/themes/RHEL
for i in firstboot/* ; do
  install -p -m 644 $i $RPM_BUILD_ROOT%{_datadir}/firstboot/themes/RHEL
done

mkdir -p $RPM_BUILD_ROOT%{_datadir}/pixmaps
for i in pixmaps/* ; do
  install -p -m 644 $i $RPM_BUILD_ROOT%{_datadir}/pixmaps
done

mkdir -p $RPM_BUILD_ROOT%{_datadir}/plymouth/themes/charge
for i in plymouth/charge/* ; do
  install -p -m 644 $i $RPM_BUILD_ROOT%{_datadir}/plymouth/themes/charge
done

mkdir -p $RPM_BUILD_ROOT%{_datadir}/plymouth/themes/rings
for i in plymouth/rings/* ; do
  install -p -m 644 $i $RPM_BUILD_ROOT%{_datadir}/plymouth/themes/rings
done

for size in 16x16 24x24 32x32 36x36 48x48 96x96 ; do
  mkdir -p $RPM_BUILD_ROOT%{_datadir}/icons/hicolor/$size/apps
  for i in icons/hicolor/$size/apps/* ; do
    install -p -m 644 $i $RPM_BUILD_ROOT%{_datadir}/icons/hicolor/$size/apps
  done
done
mkdir -p $RPM_BUILD_ROOT%{_sysconfdir}
pushd $RPM_BUILD_ROOT%{_sysconfdir}
ln -s %{_datadir}/icons/hicolor/16x16/apps/system-logo-icon.png favicon.png
popd

mkdir -p $RPM_BUILD_ROOT%{_datadir}/icons/hicolor/scalable/apps
install -p -m 644 icons/hicolor/scalable/apps/xfce4_xicon1.svg $RPM_BUILD_ROOT%{_datadir}/icons/hicolor/scalable/apps

(cd anaconda; make DESTDIR=$RPM_BUILD_ROOT install)

for i in 16 24 32 36 48 96; do
  mkdir -p $RPM_BUILD_ROOT%{_datadir}/icons/System/${i}x${i}/places
  install -p -m 644 -D $RPM_BUILD_ROOT%{_datadir}/icons/hicolor/${i}x${i}/apps/system-logo-icon.png $RPM_BUILD_ROOT%{_datadir}/icons/System/${i}x${i}/places/start-here.png
  install -p -m 644 -D $RPM_BUILD_ROOT%{_datadir}/icons/hicolor/${i}x${i}/apps/system-logo-icon.png $RPM_BUILD_ROOT%{_datadir}/kde-settings/kde-profile/default/share/icons/Fedora-KDE/${i}x${i}/places/start-here.png 
done

# ksplash theme
mkdir -p $RPM_BUILD_ROOT%{_kde4_appsdir}/ksplash/Themes/
cp -rp kde-splash/RHEL6/ $RPM_BUILD_ROOT%{_kde4_appsdir}/ksplash/Themes/
pushd $RPM_BUILD_ROOT%{_kde4_appsdir}/ksplash/Themes/RHEL6/1920x1200/
ln -s %{_datadir}/anaconda/pixmaps/splash.png splash.png
ln -s %{_datadir}/backgrounds/default.png background.png
popd

# kdm theme
mkdir -p $RPM_BUILD_ROOT/%{_kde4_appsdir}/kdm/themes/
cp -rp kde-kdm/RHEL6/ $RPM_BUILD_ROOT/%{_kde4_appsdir}/kdm/themes/
pushd $RPM_BUILD_ROOT/%{_kde4_appsdir}/kdm/themes/RHEL6/
popd

# wallpaper theme
mkdir -p $RPM_BUILD_ROOT/%{_datadir}/wallpapers/
cp -rp kde-plasma/RHEL6/ $RPM_BUILD_ROOT/%{_datadir}/wallpapers
pushd $RPM_BUILD_ROOT/%{_datadir}/wallpapers/RHEL6/contents/images
#ln -s %{_datadir}/backgrounds/1920x1200_day.png 1920x1200.png
ln -s %{_datadir}/backgrounds/default.png 1920x1200.png
popd

%clean
rm -rf $RPM_BUILD_ROOT

%post
touch --no-create %{_datadir}/icons/hicolor || :
touch --no-create %{_datadir}/icons/System || :
touch --no-create %{_datadir}/kde-settings/kde-profile/default/share/icons/Fedora-KDE ||:
if [ -x /usr/bin/gtk-update-icon-cache ]; then
  if [ -f %{_datadir}/icons/hicolor/index.theme ]; then
    gtk-update-icon-cache %{_datadir}/icons/hicolor &> /dev/null || :
  fi
  if [ -f %{_datadir}/icons/System/index.theme ]; then
    gtk-update-icon-cache %{_datadir}/icons/System &> /dev/null || :
  fi
fi

%files
%defattr(-, root, root, -)
%doc COPYING
%config(noreplace) %{_sysconfdir}/favicon.png
%{_datadir}/backgrounds/*
%{_datadir}/gnome-background-properties/*
%{_datadir}/firstboot/themes/RHEL/
%{_datadir}/plymouth/themes/charge/
%{_datadir}/plymouth/themes/rings/
%{_datadir}/kde-settings/kde-profile/default/share/icons/Fedora-KDE/*/places/*
%{_datadir}/pixmaps/*
%{_datadir}/anaconda/pixmaps/*
%{_datadir}/icons/hicolor/*/apps/*
%{_datadir}/icons/System/*/places/*

%{anaconda_image_prefix}/boot/*png
%{anaconda_image_prefix}/*.sh
%{anaconda_image_prefix}/*.jpg
%{_kde4_appsdir}/ksplash/Themes/RHEL6/
%{_kde4_appsdir}/kdm/themes/RHEL6/
%{_kde4_datadir}/wallpapers/RHEL6/

# we multi-own these directories, so as not to require the packages that
# provide them, thereby dragging in excess dependencies.
%dir %{_datadir}/icons/hicolor
%dir %{anaconda_image_prefix}
%dir %{anaconda_image_prefix}/boot
%dir %{_datadir}/anaconda
%dir %{_datadir}/anaconda/pixmaps/
%dir %{_datadir}/kde-settings
%dir %{_datadir}/kde-settings/kde-profile
%dir %{_datadir}/kde-settings/kde-profile/default
%dir %{_datadir}/kde-settings/kde-profile/default/share
%dir %{_datadir}/kde-settings/kde-profile/default/share/icons
%dir %{_datadir}/kde-settings/kde-profile/default/share/icons/Fedora-KDE
%dir %{_datadir}/kde-settings/kde-profile/default/share/icons/Fedora-KDE/16x16
%dir %{_datadir}/kde-settings/kde-profile/default/share/icons/Fedora-KDE/16x16/places
%dir %{_datadir}/kde-settings/kde-profile/default/share/icons/Fedora-KDE/24x24
%dir %{_datadir}/kde-settings/kde-profile/default/share/icons/Fedora-KDE/24x24/places
%dir %{_datadir}/kde-settings/kde-profile/default/share/icons/Fedora-KDE/32x32
%dir %{_datadir}/kde-settings/kde-profile/default/share/icons/Fedora-KDE/32x32/places
%dir %{_datadir}/kde-settings/kde-profile/default/share/icons/Fedora-KDE/36x36
%dir %{_datadir}/kde-settings/kde-profile/default/share/icons/Fedora-KDE/36x36/places
%dir %{_datadir}/kde-settings/kde-profile/default/share/icons/Fedora-KDE/48x48
%dir %{_datadir}/kde-settings/kde-profile/default/share/icons/Fedora-KDE/48x48/places
%dir %{_datadir}/kde-settings/kde-profile/default/share/icons/Fedora-KDE/96x96
%dir %{_datadir}/kde-settings/kde-profile/default/share/icons/Fedora-KDE/96x96/places
%dir %{_kde4_appsdir}
# should be ifarch i386
/boot/grub/splash.xpm.gz
# end i386 bits

%changelog

* Tue Nov 23 2010 Shawn Thompson <superfox436@gmail.com>  60.0.14-1.asc-0.1
- Put in temporary Ascendos artwork (and SL's charge theme just for now)
- Change ring throbber to something cooler for now

* Wed Aug 25 2010 Ray Strode <rstrode@redhat.com> 60.0.14-1
- Update description and COPYING file
  Resolves: #627374

* Fri Jul 30 2010 Ray Strode <rstrode@redhat.com> 60.0.13-1
- Add header image
  Related: #558608

* Fri Jul 16 2010 Ray Strode <rstrode@redhat.com> 60.0.12-1
- Drop glow theme
  Resolves: #615251

* Tue Jun 15 2010 Matthias Clasen <mclasen@redhat.com> 60.0.11-2
- Silence gtk-update-icon-cache in %%post and %%postun
Resolves: #589983

* Fri May 21 2010 Ray Strode <rstrode@redhat.com> 60.0.11-1
- Update anaconda artwork based on feedback
  Resolves: #594825

* Tue May 11 2010 Than Ngo <than@redhat.com> - 60.0.10-1
- update ksplash theme to match the latest splash

* Thu May 06 2010 Ray Strode <rstrode@redhat.com> 60.0.9-1
- Add back grub.splash
  Resolves: 589703
- Add extra frame to plymouth splash
  Related: #558608

* Wed May 05 2010 Ray Strode <rstrode@redhat.com> 60.0.8-1
- Add large logo for compiz easter egg
  Resolves: #582411
- Drop Bluecurve
  Related: #559765
- Install logo icons in System theme
  Related: #566370

* Tue May 04 2010 Ray Strode <rstrode@redhat.com> 60.0.7-1
- Rename firstboot theme to RHEL
  Resolves: #566173
- Add new plymouth artwork
  Related: #558608
- Update backgrounds
- Update anaconda
- Drop gnome-splash
- Drop empty screensaver dir
  Resolves: #576912
- Drop grub splash at request of artists

* Thu Apr 22 2010 Than Ngo <than@redhat.com> - 60.0.6-1
- fix many cosmetic issues in kdm/ksplash theme

* Mon Apr 12 2010 Ray Strode <rstrode@redhat.com> 60.0.5-3
Resolves: #576912
- Readd default.xml

* Fri Apr 09 2010 Ray Strode <rstrode@redhat.com> 60.0.5-2
- Make the upgrade path from alpha a little smoother
  Resolves: #580475

* Wed Apr 07 2010 Ray Strode <rstrode@redhat.com> 60.0.5-1
Resolves: #576912
- Update wallpapers

* Tue Feb 23 2010 Ray Strode <rstrode@redhat.com> 60.0.4-3
Resolves: #559695
- Drop xpm symlinking logic
- hide anaconda image dir behind macro

* Wed Feb 17 2010 Ray Strode <rstrode@redhat.com> 60.0.4-1
Resolves: #565886
- One more update to the KDE artwork
- Revert firstboot theme rename until later since compat link
  is causing problems.

* Wed Feb 17 2010 Ray Strode <rstrode@redhat.com> 60.0.3-1
Resolves: #565886
- Put backgrounds here since they're "trade dress"
- Rename firstboot theme from leonidas to RHEL (with compat link)

* Wed Feb 17 2010 Jaroslav Reznik <jreznik@redhat.com> 60.0.2-1
- KDE theme merged into redhat-logos package
- updated license (year in copyright)

* Fri Feb 05 2010 Ray Strode <rstrode@redhat.com> 60.0.1-3
Resolves: #559695
- spec file cleanups

* Mon Jan 25 2010 Than Ngo <than@redhat.com> - 60.0.1-2
- drop useless leonidas in KDE

* Fri Jan 22 2010 Ray Strode <rstrode@redhat.com> 60.0.1-1
Resolves: #556906
- Add updated artwork for Beta

* Thu Jan 21 2010 Matthias Clasen <mclasen@redhat.com> 60.0.0-2
- Remove a non-UTF-8 char from the spec
 
* Wed Jan 20 2010 Ray Strode <rstrode@redhat.com> 60.0.0-1
Resolves: #556906
- Add bits from glow plymouth theme

* Wed Jan 20 2010 Ray Strode <rstrode@redhat.com> - 11.90.4-1
Resolves: #556906
- Update artwork for Beta

* Tue Dec 08 2009 Dennis Gregorovic <dgregor@redhat.com> - 11.90.3-1.1
- Rebuilt for RHEL 6

* Mon Jun 01 2009 Ray Strode <rstrode@redhat.com> - 11.90.3-1
- remove some of the aliasing from the charge theme

* Thu May 29 2009 Ray Strode <rstrode@redhat.com> - 11.90.2-1
- Drop backgrounds again because they don't actually contain logos

* Thu May 29 2009 Ray Strode <rstrode@redhat.com> - 11.90.1-1
- Install new backgrounds

* Fri May 29 2009 Ray Strode <rstrode@redhat.com> - 11.90.0-2
- Rebuild using tarball dist from cvs

* Thu May 28 2009 Ray Strode <rstrode@redhat.com> - 11.90.0-1
- Update artwork for RHEL 6 alpha

* Thu Jan  4 2007 Jeremy Katz <katzj@redhat.com> - 4.9.16-1
- Fix syslinux splash conversion, Resolves: #209201

* Fri Dec  1 2006 Matthias Clasen <mclasen@redhat.com> - 4.9.15-1
- Readd rhgb/main-logo.png, Resolves: #214868

* Tue Nov 28 2006 David Zeuthen <davidz@redhat.com> - 4.9.14-1
- Don't include LILO splash. Resolves: #216748
- New syslinux-splash from Diana Fong. Resolves: #217493

* Tue Nov 21 2006 David Zeuthen <davidz@redhat.com> - 4.9.13-1
- Make firstboot/splash-small.png completely transparent
- Fix up date for last commit
- Resolves: #216501

* Mon Nov 20 2006 David Zeuthen <davidz@redhat.com> - 4.9.12-1
- New shadowman gdm logo from Diana Fong (#216370)

* Wed Nov 15 2006 David Zeuthen <davidz@redhat.com> - 4.9.10-1
- New shadowman logos from Diana Fong (#215614)

* Fri Nov 10 2006 Than Ngo <than@redhat.com> - 4.9.9-1
- add missing KDE splash (#212130)

* Wed Oct 25 2006 David Zeuthen <davidz@redhat.com> - 4.9.8-1
- Add new shadowman logos (#211837)

* Mon Oct 23 2006 Matthias Clasen <mclasen@redhat.com> - 4.9.7-1 
- Include the xml file in the tarball

* Mon Oct 23 2006 Matthias Clasen <mclasen@redhat.com> - 4.9.6-1
- Add names for the default background (#211556)

* Tue Oct 17 2006 Matthias Clasen <mclasen@redhat.com> - 4.9.5-1
- Update the url pointing to the trademark policy (#187124)

* Thu Oct  5 2006 Matthias Clasen <mclasen@redhat.com> - 4.9.4-1
- Fix some colormap issues in the syslinux-splash (#209201)

* Wed Sep 20 2006 Ray Strode <rstrode@redhat.com> - 4.9.2-1
- ship new artwork from Diana Fong for login screen

* Tue Sep 19 2006 John (J5) Palmieri <johnp@redhat.com> - 1.2.8-1
- Fix packager to dist the xml background file

* Tue Sep 19 2006 John (J5) Palmieri <johnp@redhat.com> - 1.2.7-1
- Add background xml file for the new backgrounds
- Add po directory for translating the background xml

* Tue Sep 19 2006 John (J5) Palmieri <johnp@redhat.com> - 1.2.6-1
- Add new RHEL graphics

* Fri Aug 25 2006 John (J5) Palmieri <johnp@redhat.com> - 1.2.5-1
- Modify the anaconda/splash.png file to say Beta instead of Alpha

* Tue Aug 01 2006 John (J5) Palmieri <johnp@redhat.com> - 1.2.4-1
- Add firstboot-left to the firstboot images

* Fri Jul 28 2006 John (J5) Palmieri <johnp@redhat.com> - 1.2.3-1
- Add attributions to the background graphics metadata
- Add a 4:3 asspect ratio version of the default background graphic

* Thu Jul 27 2006 John (J5) Palmieri <johnp@redhat.com> - 1.2.2-1
- Add default backgrounds

* Wed Jul 12 2006 Matthias Clasen <mclasen@redhat.com> - 1.2.1-1
- Add system lock dialog

* Thu Jun 15 2006 Jeremy Katz <katzj@redhat.com> - 1.2.0-1
- alpha graphics

* Wed Aug  3 2005 David Zeuthen <davidz@redhat.com> - 1.1.26-1
- Add russian localisation for rnotes (#160738)

* Thu Dec  2 2004 Jeremy Katz <katzj@redhat.com> - 1.1.25-1
- add rnotes

* Fri Nov 19 2004 Alexander Larsson <alexl@redhat.com> - 1.1.24-1
- Add rhgb logo (#139788)

* Mon Nov  1 2004 Alexander Larsson <alexl@redhat.com> - 1.1.22-1
- Move rh logo from redhat-artwork here (#137593)

* Fri Oct 29 2004 Alexander Larsson <alexl@redhat.com> - 1.1.21-1
- Fix alignment of gnome splash screen (#137360)

* Fri Oct  1 2004 Alexander Larsson <alexl@redhat.com> - 1.1.20-1
- New gnome splash

* Tue Aug 24 2004 Jeremy Katz <katzj@redhat.com> - 1.1.19-1
- update firstboot splash

* Sat Jun  5 2004 Jeremy Katz <katzj@redhat.com> - 1.1.18-1
- provides: system-logos

* Thu Jun  3 2004 Jeremy Katz <katzj@redhat.com> - 1.1.17-1
- add anaconda bits

* Tue Mar 23 2004 Alexander Larsson <alexl@redhat.com> 1.1.16-1
- fix the logos in the gdm theme

* Fri Jul 18 2003 Havoc Pennington <hp@redhat.com> 1.1.15-1
- build new stuff from garrett

* Wed Feb 26 2003 Havoc Pennington <hp@redhat.com> 1.1.14-1
- build new stuff in cvs

* Mon Feb 24 2003 Jeremy Katz <katzj@redhat.com> 1.1.12-1
- updated again
- actually update the grub splash

* Fri Feb 21 2003 Jeremy Katz <katzj@redhat.com> 1.1.11-1
- updated splash screens from Garrett

* Tue Feb 18 2003 Havoc Pennington <hp@redhat.com> 1.1.10-1
- move in a logo from gdm theme #84543

* Mon Feb  3 2003 Havoc Pennington <hp@redhat.com> 1.1.9-1
- rebuild

* Wed Jan 15 2003 Brent Fox <bfox@redhat.com> 1.1.8-1
- rebuild for completeness

* Mon Dec 16 2002 Havoc Pennington <hp@redhat.com>
- rebuild

* Thu Sep  5 2002 Havoc Pennington <hp@redhat.com>
- add firstboot images to makefile/specfile
- add /usr/share/pixmaps stuff
- add splash screen images
- add COPYING

* Thu Sep  5 2002 Jeremy Katz <katzj@redhat.com>
- add boot loader images

* Thu Sep  5 2002 Havoc Pennington <hp@redhat.com>
- move package to CVS

* Tue Jun 25 2002 Owen Taylor <otaylor@redhat.com>
- Add a shadowman-only derived from redhat-transparent.png

* Thu May 23 2002 Tim Powers <timp@redhat.com>
- automated rebuild

* Wed Jan 09 2002 Tim Powers <timp@redhat.com>
- automated rebuild

* Thu May 31 2001 Owen Taylor <otaylor@redhat.com>
- Fix alpha channel in redhat-transparent.png

* Wed Jul 12 2000 Prospector <bugzilla@redhat.com>
- automatic rebuild

* Mon Jun 19 2000 Owen Taylor <otaylor@redhat.com>
- Add %%defattr

* Mon Jun 19 2000 Owen Taylor <otaylor@redhat.com>
- Add version of logo for embossing on the desktop

* Tue May 16 2000 Preston Brown <pbrown@redhat.com>
- add black and white version of our logo (for screensaver).

* Mon Feb 07 2000 Preston Brown <pbrown@redhat.com>
- rebuild for new description.

* Fri Sep 25 1999 Bill Nottingham <notting@redhat.com>
- different.

* Mon Sep 13 1999 Preston Brown <pbrown@redhat.com>
- added transparent mini and 32x32 round icons

* Sat Apr 10 1999 Michael Fulbright <drmike@redhat.com>
- added rhad logos

* Thu Apr 08 1999 Bill Nottingham <notting@redhat.com>
- added smaller redhat logo for use on web page

* Wed Apr 07 1999 Preston Brown <pbrown@redhat.com>
- added transparent large redhat logo

* Tue Apr 06 1999 Bill Nottingham <notting@redhat.com>
- added mini-* links to make AnotherLevel happy

* Mon Apr 05 1999 Preston Brown <pbrown@redhat.com>
- added copyright

* Tue Mar 30 1999 Michael Fulbright <drmike@redhat.com>
- added 48 pixel rounded logo image for gmc use

* Mon Mar 29 1999 Preston Brown <pbrown@redhat.com>
- package created