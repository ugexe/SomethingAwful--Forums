package SomethingAwful::Forums::Scraper::Index;
use strict;
use Web::Scraper;

our $VERSION = '0.01';

sub new {
    return scraper {
        process '//div[@id="probation_warn"]', 
            probated => sub { return 1; };
        process '//table[@id="info"]//tr//th', 
            logged_in_user_count => sub {
                my $result = $_[0]->as_text =~ s{^.*?([\d,]+) users logged in.*?$}{$1}ir;
                $result =~ tr/,//d;
                return $result;
            };

        process '//td[@class="users"]', 
            registered_logged_in_user_count => sub {
                my $result = $_[0]->as_text =~ s{^.*?([\d,]+) registered users.*?$}{$1}ir;
                $result =~ tr/,//d;
                return $result;
            },
            total_user_count => sub { 
                my $result = $_[0]->as_text =~ s{^.*?([\d,]+) users total.*?$}{$1}ir;
                $result =~ tr/,//d;
                return $result;
            };

        process '//td[@class="posts"]', 
            thread_count => sub { 
                my $result = $_[0]->as_text =~ s{^.*?([\d,]+) total threads.*?$}{$1}ir;
                $result =~ tr/,//d;
                return $result;
            },
            post_count   => sub { 
                my $result = $_[0]->as_text =~ s{^.*?([\d,]+) total posts.*?$}{$1}ir;
                $result =~ tr/,//d;
                return $result;
            };

        process '//td[@class="archived"]', 
            archived_thread_count => sub { 
                my $result = $_[0]->as_text =~ s{^.*?([\d,]+) archived threads.*?$}{$1}ir;
                $result =~ tr/,//d;
                return $result;
            },
            archived_post_count   => sub { 
                my $result = $_[0]->as_text =~ s{^.*?([\d,]+) archived posts.*?$}{$1}ir;
                $result =~ tr/,//d;
                return $result;            
            };

        process '//td[@class="banned"]', 
            today_ban_count => sub { 
                my $result = $_[0]->as_text =~ s{^.*?([\d,]+) users banned today.*?$}{$1}ir;
                $result =~ tr/,//d;
                return $result;
            },
            total_ban_count => sub { 
                my $result = $_[0]->as_text =~ s{^.*?([\d,]+) total users banned.*?$}{$1}ir;
                $result =~ tr/,//d;
                return $result;
            };

        process '//div[@class="mainbodytextsmall"][contains(text(), "Hello, ")]//a[1]', 
            logged_in_as_username => 'TEXT',
            logged_in_as_id       => sub {
                return ($_[0]->attr('href') =~ s{^.*?userid=(\d+).*?$}{$1}ir);     
            };

        process '//table[@id="pm"]//tr[2]//td[1]', 
            pm_info => sub {
                return {
                    total  => ($_[0]->as_text =~ s{^.*?([\d,]+) total messages.*?$}{$1}ir),
                    unread => ($_[0]->as_text =~ s{^.*?([\d,]+) unread messages.*?$}{$1}ir),
                    new    => ($_[0]->as_text =~ s{^.*?([\d,]+) new messages.*?$}{$1}ir),
                };
            };

        process '//a[contains(@href, "action=logout")]', 
            logout_uri => '@href';

        # Forum specific data
        process '//tr[contains(@class, "forum")]', 
            'forums[]' => scraper {
                # Main Forum
                process '//td[@class="title"]//a[@class="forum"]', 
                    uri  => '@href', 
                    name => 'TEXT', 
                    id   => sub { 
                        return ($_[0]->attr('href') =~ s{^.*forumid=(\d+).*?$}{$1}ir); 
                    };

                # Sub Forums
                process '//td[@class="title"]//div[@class="subforums"]//a[contains(@class, "forum")]', 
                    'subforums[]' => { 
                            uri     => '@href', 
                            name    => 'TEXT', 
                            id      => sub {
                                return ($_[0]->attr('href') =~ m{forumid=\d+}i
                                        ? ($_[0]->attr('href') =~ s{^.*forumid=(\d+).*?$}{$1}ir)
                                        : ($_[0]->attr('class') =~ m{forum_\d+}i
                                            ? ($_[0]->attr('class') =~ s{^.*?forum_(\d+).*?$}{$1}ir)
                                            : undef
                                        )
                                );
                            }
                    };

                # Moderators
                process '//td[@class="moderators"]//a', 
                    'moderators[]' => {
                        uri  => '@href',
                        name => 'TEXT',
                        id   => sub {
                            return ($_[0]->attr('href') =~ s{userid=(\d+)}{$1}ir);
                        }
                    };
            };
    };
}


1;


__END__
