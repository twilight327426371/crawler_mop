use Mojo::UserAgent; 
use 5.010;
use YAML 'Dump';
use Mojo::IOLoop;
use Mojo::DOM;
use File::Spec;
use Encode qw(decode encode decode_utf8 encode_utf8);




    




my $feed = shift || warn "Usage: perl down_jpg_mop.pl http://dzh.mop.com/picarea";
my $ua = Mojo::UserAgent->new;

my @shtml=();
my ($feed2) = $feed=~ m/(.+)\//;
for my $e ($ua->get($feed)->res->dom->find('a')->each)
    {
        #say $e;
        my $node = $e->find('a.[target="rightframe"]')->first;
        #say $node;
        #say $node->{href};
        #say $feed2;
        my $link=$feed2.$node->{href}."?only=1&dzhrefer=true";
        if ($node->{href} =~ m/shtml/) {
            my $newnode=Mojo::DOM->new($node);
            push @shtml , {
            
                link => $link,
                name => $newnode->a->text,
                download_urls=>fetch_jpg_download($link),
        };
        };

};

download_jpg(\@shtml,'/tmp');
#say Dump( \@shtml );

sub download_jpg {
    my ($download_info,$path)=@_;
    for my $s (@$download_info){
        next unless $s->{name};
        say $s->{name};
        #say $s->{download_urls};
        for my $d (@{$s->{download_urls}}){
            #say $abs_name;
            my $abs_path = File::Spec->catfile($path,$s->{name});
            my ($name) = $d->{download_url} =~ m/.*\/(\d+)/;
            #say $name;
            my $file = File::Spec->catfile($abs_path,
                $name.".jpg");
            #my $abs_name=encode('gb2312',$s->{name});
            #my $new_abs_path = File::Spec->catfile($path,$abs_name);
            #say $new_abs_path;
            if (not -d $abs_path) {
                mkdir $abs_path;
            }
            my $tx=$ua->get($d->{download_url});
            $tx->res->content->asset->move_to($file);
            $d->{downloaded_jpg} = $file if -e $file;

        }
        #system("mv $abs_path $new_abs_path");
    }

}


sub fetch_jpg_download {
    my ($url)=@_;
    my $tx = $ua->get($url);
    my @downloads;
    if ($tx->success) {
        for my $e ($tx->res->dom->find('div.[id="body"]')->each){
                for my $d (@{$e->find('img')}){
                    push @downloads,{
                        download_url=>$d->{src},
                    };
                };
           }
    }    
    else {
        say "got download box failed";
    }
    return \@downloads;
}
