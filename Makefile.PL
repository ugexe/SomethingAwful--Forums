use strict;
use warnings; 
use ExtUtils::MakeMaker;

my $pm =   'lib/SomethingAwful/Forums.pm';
my $repo = 'https://github.com/ugexe/SomethingAwful--Forums';
my $bugs = 'https://github.com/ugexe/SomethingAwful--Forums/issues';
 
WriteMakefile (  
    NAME           => 'SomethingAwful::Forums',
    VERSION_FROM   => $pm, 
    ABSTRACT_FROM  => $pm,
    AUTHOR         => 'Nick Logan <ugexe@cpan.org>',
    LICENSE        => 'perl',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM      => {
        'Web::Scraper'              => 0,
        'WWW::Mechanize'            => 0,
        'Web::Scraper::LibXML'      => 0, # These 2 can be subbed out for just Web::Scraper
        'HTML::TreeBuilder::LibXML' => 0, # but its slower. Figure out how to do this automatically.
        'Regexp::Common'            => 0,
        'Moose'                     => 0,
        'Method::Signatures'        => 0,
        'Coro'                      => 0,
        'URI'                       => 0,
        'namespace::autoclean'      => 0,
        'Modern::Perl'              => 0,
        'LWP::Protocol::AnyEvent::http' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'        => 0,
    },
    META_MERGE => {
        resources => {
            repository => $repo, 
            bugtracker => "$bugs",
        },
        provides => {
            'SomethingAwful::Forums::Scraper::Index' => {
                file    => 'lib/SomethingAwful::Forums::Scraper::Index.pm',
                version => '0.01',
            },
            'SomethingAwful::Forums::Scraper::Forum' => {
                file    => 'lib/SomethingAwful::Forums::Scraper::Forum.pm',
                version => '0.01',
            },
            'SomethingAwful::Forums::Scraper::Thread' => {
                file    => 'lib/SomethingAwful::Forums::Scraper::Thread.pm',
                version => '0.01',
            },
        },
    },
);