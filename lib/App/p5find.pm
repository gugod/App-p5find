package App::p5find;
use v5.18;
use File::Next;

use Exporter 'import';
our @EXPORT_OK = qw(p5_source_file_iterator);

my %EXCLUDED = (
    '.git' => 1,
    '.svn' => 1,
    'CVS'  => 1,
    'node_modules' => 1,
);

sub p5_source_file_iterator {
    my ($dir) = @_;
    my $files = File::Next::files(
        +{ descend_filter => sub { ! $EXCLUDED{$_} } },
        $dir
    );
    return sub {
        my $f;
        do { $f = $files->() } while $f && ! is_perl5_source_file($f);
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
