Summary: Convert text files between various Esperanto encodings
Name: eoconv
Version: 1.4
Release: 1
License: GPL
Group: Applications/Text
URL: http://www.nothingisreal.com/eoconv/
Source0: http://www.nothingisreal.com/eoconv/%{name}-%{version}.tar.bz2
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
Prefix: %{_prefix}
Requires: perl >= 5.6
Distribution: SuSE 11.4 (noarch)
BuildArch: noarch

%description
eoconv is a tool which converts text files to and from the following
Esperanto text encodings:

  * ASCII postfix h notation
  * ASCII postfix x notation
  * ASCII postfix caret (^) notation
  * ASCII prefix caret (^) notation
  * ISO-8859-3
  * Unicode (UTF-7, UTF-8, UTF-16, UTF-32)
  * HTML entities (decimal or hexadecimal)
  * LaTeX sequences


%prep
%setup -q

%build

%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT
install -D eoconv.pl $RPM_BUILD_ROOT%{_prefix}/bin/eoconv
gzip doc/eoconv.1
install -D doc/eoconv.1.gz $RPM_BUILD_ROOT%{_prefix}/share/man/man1/eoconv.1.gz

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root,-)
%{_prefix}/bin/eoconv
%doc AUTHORS COPYING INSTALL NEWS README THANKS
%doc %{_prefix}/share/man/man1/eoconv.1.gz



%changelog
* Tue Oct 15 2013 Tristan Miller <psychonaut@nothingisreal.com> - 
- Initial build.

