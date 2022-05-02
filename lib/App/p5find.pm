package App::p5find;
use v5.18;
use warnings;

our $VERSION = "0.06";

use File::Next;
use PPI::Document::File;
use PPIx::QuoteLike;

use Exporter 'import';
our @EXPORT_OK = qw(
                       p5_doc_iterator
                       p5_find_iterator
                       p5_source_file_iterator
                       p5_method_call_iterator
                       print_file_linenum_line
                       print_only_matching
                       iter_each
               );

my %EXCLUDED = (
    '.git' => 1,
    '.svn' => 1,
    'CVS'  => 1,
    'node_modules' => 1, # You won't hide your Perl5 code there, right ?
);

sub p5_doc_iterator {
    my (@paths) = @_;
    my $files = p5_source_file_iterator(@paths);
    return sub {
        my $f = $files->();
        return undef unless defined($f);
        my $dom = PPI::Document::File->new( $f, readonly => 1 );
        return undef unless defined($dom);
        $dom->index_locations;
        return $dom;
    };
}

sub p5_source_file_iterator {
    my (@paths) = @_;
    my $files = File::Next::files(
        +{ descend_filter => sub { ! $EXCLUDED{$_} } },
        @paths
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

sub print_file_linenum_line {
    my ($file, $to_print) = @_;

    my $line_number = 0;
    open my $fh, "<", $file;
    while (my $line = <$fh>) {
        $line_number++;
        if ( $to_print->{$line_number} ) {
            print "${file}:${line_number}:${line}";
        }
    }
    close($fh);
}

sub print_only_matching {
    my ($file, $to_print) = @_;

    for my $line_number (sort { $a <=> $b } keys %$to_print) {
        print $to_print->{$line_number} . "\n";
    }
}

sub p5_method_call_iterator {
    my ($doc) = @_;

    my $arrows = $doc->find(
        sub {
            my $op = $_[1];
            return 0 unless $op->isa("PPI::Token::Operator") && $op->content eq '->';
            my $op_next = $op->snext_sibling or return 0;
            return 0 if $op_next->isa("PPI::Structure::Subscript") || $op_next->isa("PPI::Structure::List");
            return 1;
        }
    ) || [];

    return sub {
        return @$arrows ? shift(@$arrows) : undef;
    };
}

sub p5_find_iterator {
    my ($doc, $cb) = @_;
    my $found = $doc->find($cb) || [];
    return sub {
        @$found ? shift(@$found) : undef
    }
}

sub iter_each {
    my ($iter, $cb) = @_;
    while (my $it = $iter->()) {
        last unless defined $cb->($it);
    }
}

1;

__END__

=head1 NAME

App::p5find - A collection of programs for locating certain constructs in Perl5 code.

=head1 DESCRIPTION

This distribution provides a collection of programs that search through Perl5
code structure for certain patterns. Such as: string literals with
interpolations, bareword tokens, vairable in method names.

While those code patterns may be discoverable with sufficient amount of
ack/grep-fu, this projects aims to reduce the amount of false recalls to the
point that it becomes usefull for tasks such as hunting for anti-patterns.

=head1 The p5find command

This distribution gives you a dozen of commands, all named like
C<p5find-something>, as well as master command name just
C<p5find>. The command name usually refer to a type of object or code
pattern that can be located by running that command. For example,
C<p5find-num> would list up all number literals, while C<p5find-str>
would list up all string literals.

Except for a few special ones, running all p5find commands would start
iterating all perl source find under current working directory then
looking for the specified code pattern.

For example, to locate string literals, run: C<p5find str> (or
C<p5find-str>). To see all options of the command, pass C<-h>.
Or for slightly more reading materials, run C<perldoc p5find-str>.

Conventionally the documentation all p5find commands can be revealed
by invoking it with C<-h>, or by running C<perldoc> on it.

To start understanding the usages of p5find, run: C<p5find
help>, or C<p5find-help>

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 LICENSE

MIT

=cut
