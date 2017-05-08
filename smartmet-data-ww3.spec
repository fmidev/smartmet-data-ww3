%define smartmetroot /smartmet

Name:           smartmet-data-ww3
Version:        17.5.8
Release:        1%{?dist}.fmi
Summary:        SmartMet Data WW3
Group:          System Environment/Base
License:        MIT
URL:            https://github.com/fmidev/smartmet-data-ww3
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:	noarch

Requires:	smartmet-qdconversion
Requires:	bzip2


%description
SmartMet data ingest module for Wave Watch 3 model.

%prep

%build

%pre

%install
rm -rf $RPM_BUILD_ROOT
mkdir $RPM_BUILD_ROOT
cd $RPM_BUILD_ROOT

mkdir -p .%{smartmetroot}/cnf/cron/{cron.d,cron.hourly}
mkdir -p .%{smartmetroot}/cnf/data
mkdir -p .%{smartmetroot}/tmp/data/ww3
mkdir -p .%{smartmetroot}/logs/data
mkdir -p .%{smartmetroot}/run/data/ww3/{bin,cnf}
mkdir -p .%{smartmetroot}/data/ww3

cat > %{buildroot}%{smartmetroot}/cnf/cron/cron.d/ww3.cron <<EOF
# Model available after
# 00 UTC = 04:20 UTC
20 * * * * utcrun 4 /smartmet/run/data/ww3/bin/doww3.sh 
# 06 UTC = 10:20 UTC
20 * * * * utcrun 10 /smartmet/run/data/ww3/bin/doww3.sh 
# 12 UTC = 16:20 UTC
20 * * * * utcrun 16 /smartmet/run/data/ww3/bin/doww3.sh 
# 18 UTC = 22:20 UTC
20 * * * * utcrun 22 /smartmet/run/data/ww3/bin/doww3.sh 
EOF

cat > %{buildroot}%{smartmetroot}/cnf/cron/cron.hourly/clean_data_ww3 <<EOF
#!/bin/sh
# Clean WW3 data
cleaner -maxfiles 4 '_ww3_.*_surface.sqd' %{smartmetroot}/data/ww3
cleaner -maxfiles 4 '_ww3_.*_surface.sqd' %{smartmetroot}/editor/in
EOF

cat > %{buildroot}%{smartmetroot}/cnf/data/ww3.cnf <<EOF
AREA="caribbean"

TOP=40
BOTTOM=-10
LEFT=-120
RIGHT=0

LEG1_START=0
LEG1_STEP=3
LEG1_END=120

LEG2_START=126
LEG2_STEP=6
LEG2_END=180
EOF


install -m 755 %_topdir/SOURCES/smartmet-data-ww3/doww3.sh %{buildroot}%{smartmetroot}/run/data/ww3/bin/
cp -f %_topdir/SOURCES/smartmet-data-ww3/wave.cnf %{buildroot}%{smartmetroot}/run/data/ww3/cnf/

%post

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,smartmet,smartmet,-)
%config(noreplace) %{smartmetroot}/cnf/data/ww3.cnf
%config(noreplace) %{smartmetroot}/cnf/cron/cron.d/ww3.cron
%config(noreplace) %{smartmetroot}/run/data/ww3/cnf/wave.cnf
%config(noreplace) %attr(0755,smartmet,smartmet) %{smartmetroot}/cnf/cron/cron.hourly/clean_data_ww3
%{smartmetroot}/*

%changelog
* Mon May 8 2017 Mikko Rauhala <mikko.rauhala@fmi.fi>  17.5.8-1.el7.fmi
- Updated dependencies
* Wed Jun 3 2015 Santeri Oksman <santeri.oksman@fmi.fi> 15.6.3-1.el7.fmi
- RHEL 7 version
* Tue Feb 3 2015 Mikko Rauhala <mikko.rauhala@fmi.fi> 15.2.3-1.el6.fmi
- After NOAA upgrade, directory location changed
