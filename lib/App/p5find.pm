package App::p5find;
use v5.18;
our $VERSION = "0.01";

use File::Next;
use PPI::Document::File;

use Exporter 'import';
our @EXPORT_OK = qw( p5_doc_iterator
                     p5_source_file_iterator);

my %EXCLUDED = (
    '.git' => 1,
    '.svn' => 1,
    'CVS'  => 1,
    'node_modules' => 1,
);

sub p5_doc_iterator {
    my ($dir) = @_;
    my $files = p5_source_file_iterator($dir);
    return sub {
        my $f = $files->();
        return undef unless defined($f);
        my $dom = PPI::Document::File->new( $f, readonly => 1 );
        $dom->index_locations;
        return $dom;
    };
}

sub p5_source_file_iterator {
    my ($dir) = @_;
    my $files = File::Next::files(
        +{ descend_filter => sub { ! $EXCLUDED{$_} } },
        $dir
    );
    return sub {
        my $f;
        do { $f = $files->() } while defined($f) && ! is_perl5_source_file($f);
        return $f;
    }
}

sub is_perl5_source_file {
    my ($file) = @_;
    return 1 if $file =~ / \.(?: t|p[ml]|pod|comp ) $/xi;
    return 0 if $file =~ / \. /xi;
    if (open my $fh, '<', $file) {
        my $line = <$fh>;
        return 1 if $line =~ m{^#!.*perl};
    }
    return 0;
}

1;

__END__

=head1 NAME

App::p5find - XXX

=head1 DESCRIPTION

A set of programs for locating certain constructs in Perl5 code.

=head1 AUTHOR

Kang-min Liu

=head1 LICENSE

MIT

=cut
