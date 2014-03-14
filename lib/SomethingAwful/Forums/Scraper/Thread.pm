package SomethingAwful::Forums::Scraper::Thread;
use strict;
use Web::Scraper::LibXML; # Web::Scraper also works, but slower
require HTML::TreeBuilder::LibXML; # only needed for Web::Scraper::LibXML

our $VERSION = '0.01';

sub new {
    return scraper {

        # Sets defaults for the next block since single page threads
        # don't have the page info in the html. Must find a better way to do this.
        process '//div[@class="pages top"]', 
            page_info => sub {
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

        process '//div[@id="thread"]//table[starts-with(@id, "post")]', 
            'posts[]' => scraper {
                process '//td[starts-with(@class, "userinfo")]', 
                    author_info => sub {
                        return ($_[0]->attr('class') =~ s{^.*?userid-(\d+).*?$}{$1}ir);
                    }, 
                    authorinfo => scraper {
                        process '//dt[@class="author"]',     
                            username => 'TEXT';
                        process '//dd[@class="registered"]', 
                            regdate  => 'TEXT';
                        process '//dd[@class="title"]/br',
                            title    => 'TEXT';
                        process '//dd[@class="title"][//img[1]/br/br]/img', 
                            avatar   => '@href'; 
                    };
                process '//td[@class="postbody"]', 
                    body => sub { 
                        # Need to change to read in HTML so users can parse out quotes 
                        # ->as_HTML may work
                        return $_[0]->as_text; 
                    },
                    body_no_quotes => sub { 
                        my $node = $_[0]->clone;

                        foreach my $n ( $node->findnodes('//div[@class="bbc-block"]') ) {
                            $n->delete;
                        }

                        return $node->as_text;
                    };
                process '//td[@class="postdate"]//a[text()="#"]', 
                    post_id => sub {
                        return ($_[0]->attr('href') =~ s{^.*?#post(\d+).*?$}{$1}ir);
                    }; 
                process '//td[@class="postdate"]//a[@class="user_jump"]', 
                    posts_by_user_uri => '@href';
                process '//td[@class="postdate"]', 
                    date => sub {
                        my $text = $_[0]->as_text;
                        $text =~ s{#}{};
                        $text =~ s{\?}{};

                        return $text;
                    };
                process '//ul[@class="profilelinks"]/li', 
                    profile_uris => scraper {
                        process '//a[text()="Profile"]',      
                            profile      => '@href'; 
                        process '//a[text()="Message"]',      
                            message      => '@href'; 
                        process '//a[text()="Post History"]', 
                            post_history => '@href'; 
                    };
                process '//ul[@class="postbuttons"]//a[contains(@href, "modalert")]', 
                    report_uri => '@href';
                process '//ul[@class="postbuttons"]//a[contains(@href, "newreply")]', 
                    reply_uri => '@href';

            };
    };
}


1;


__END__