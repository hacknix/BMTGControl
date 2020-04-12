use ExtUtils::MakeMaker;

WriteMakefile
(
	'NAME'		=>	'MMDVM::TGControl',
	'VERSION_FROM'	=>	'lib/MMDVM/TGControl/Daemon.pm',
	'PREREQ_PM'	=>	{
		'LWP::UserAgent'	=>	0,
		'JSON'			=>	0,
		'MIME::Base64'		=>	0,
		'BrandMeister::API'	=>	0.3,
		'Proc::Daemon'		=>	0,
		'File::Tail::Inotify2'	=>	0,
	}

);
