package SomethingAwful::Forums::Scraper::Users::Online;
use strict;
use Web::Scraper;

our $VERSION = '0.01';

sub new {
    return scraper {

        process '//div[@class="pages"]', 
            page_info => sub {
                # sets defaults for next block below
                return {
                    last    => 1,
                    current => 1,
                };
            },
            page_info => scraper {
                process '//select//option[last()]', 
                    last    => 'TEXT';
                process '//select//option[@selected]', 
                    current => 'TEXT';
            };

        process '//ul[@id="users"]//li[@class="admin"]//a[@href]', 'admins[]' => sub {
                return {
                    username => $_[0]->as_text,
                    id       => ($_[0] =~ s{^.*?userid=(\d+).*?$}{$1}ir),
                };
            };
        process '//ul[@id="users"]//li[@class="mod"]//a[@href]', 'mods[]' => sub {
                return {
                    username => $_[0]->as_text,
                    id       => ($_[0] =~ s{^.*?userid=(\d+).*?$}{$1}ir),
                };
            };
        process '//ul[@id="users"]//li[@class="plat"]//a[@href]', 'plats[]' => sub {
                return {
                    username => $_[0]->as_text,
                    id       => ($_[0] =~ s{^.*?userid=(\d+).*?$}{$1}ir),
                };
            };
        process '//ul[@id="users"]/li//a[@href]', 'users[]' => sub {
                return {
                    username => $_[0]->as_text,
                    id       => ($_[0] =~ s{^.*?userid=(\d+).*?$}{$1}ir),
                };
            };
    };
}


1;


__END__