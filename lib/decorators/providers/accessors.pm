package decorators::providers::accessors;
# ABSTRACT: built in traits

use strict;
use warnings;

use decorators;
use decorators::from ':for_providers';

use Carp      ();
use MOP::Util ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

sub ro : OverwriteMethod {
    my ( $meta, $method, @args ) = @_;

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        if ( $args[0] eq '_' ) {
            $slot_name = '_'.$method_name;
        }
        else {
            $slot_name = shift @args;
        }
    }
    else {
        if ( $method_name =~ /^get_(.*)$/ ) {
            $slot_name = $1;
        }
        else {
            $slot_name = $method_name;
        }
    }

    Carp::confess('Unable to build `ro` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub {
        Carp::confess("Cannot assign to `$slot_name`, it is a readonly") if scalar @_ != 1;
        $_[0]->{ $slot_name };
    });
}

sub rw : OverwriteMethod {
    my ( $meta, $method, @args ) = @_;

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        if ( $args[0] eq '_' ) {
            $slot_name = '_'.$method_name;
        }
        else {
            $slot_name = shift @args;
        }
    }
    else {
        $slot_name = $method_name;
    }

    Carp::confess('Unable to build `rw` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because class is immutable.')
        if ($meta->name)->isa('UNIVERSAL::Object::Immutable');

    Carp::confess('Unable to build `rw` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub {
        $_[0]->{ $slot_name } = $_[1] if scalar( @_ ) > 1;
        $_[0]->{ $slot_name };
    });
}

sub wo : OverwriteMethod {
    my ( $meta, $method, @args ) = @_;

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        if ( $args[0] eq '_' ) {
            $slot_name = '_'.$method_name;
        }
        else {
            $slot_name = shift @args;
        }
    }
    else {
        if ( $method_name =~ /^set_(.*)$/ ) {
            $slot_name = $1;
        }
        else {
            $slot_name = $method_name;
        }
    }

    Carp::confess('Unable to build `wo` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because class is immutable.')
        if ($meta->name)->isa('UNIVERSAL::Object::Immutable');

    Carp::confess('Unable to build `wo` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub {
        Carp::confess("You must supply a value to write to `$slot_name`") if scalar(@_) < 1;
        $_[0]->{ $slot_name } = $_[1];
    });
}

sub predicate : OverwriteMethod {
    my ( $meta, $method, @args ) = @_;

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        if ( $args[0] eq '_' ) {
            $slot_name = '_'.$method_name;
        }
        else {
            $slot_name = shift @args;
        }
    }
    else {
        if ( $method_name =~ /^has_(.*)$/ ) {
            $slot_name = $1;
        }
        else {
            $slot_name = $method_name;
        }
    }

    Carp::confess('Unable to build predicate for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub { defined $_[0]->{ $slot_name } } );
}

sub clearer : OverwriteMethod {
    my ( $meta, $method, @args ) = @_;

    my $method_name = $method->name;

    my $slot_name;
    if ( $args[0] ) {
        if ( $args[0] eq '_' ) {
            $slot_name = '_'.$method_name;
        }
        else {
            $slot_name = shift @args;
        }
    }
    else {
        if ( $method_name =~ /^clear_(.*)$/ ) {
            $slot_name = $1;
        }
        else {
            $slot_name = $method_name;
        }
    }

    Carp::confess('Unable to build `clearer` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because class is immutable.')
        if ($meta->name)->isa('UNIVERSAL::Object::Immutable');

    Carp::confess('Unable to build `clearer` accessor for slot `' . $slot_name.'` in `'.$meta->name.'` because the slot cannot be found.')
        unless $meta->has_slot( $slot_name )
            || $meta->has_slot_alias( $slot_name );

    $meta->add_method( $method_name => sub { undef $_[0]->{ $slot_name } } );
}


1;

__END__

=pod

=head1 DESCRIPTION

=over 4

=item C<ro( ?$slot_name )>

This will generate a simple read-only accessor for a slot. The
C<$slot_name> can optionally be specified, otherwise it will use the
name of the method that the trait is being applied to.

    sub foo : ro;
    sub foo : ro(_foo);

If the method name is prefixed with C<get_>, then this trait will
infer that the slot name intended is the remainder of the method's
name, minus the C<get_> prefix, such that this:

    sub get_foo : ro;

Is the equivalent of writing this:

    sub get_foo : ro(foo);

=item C<rw( ?$slot_name )>

This will generate a simple read-write accessor for a slot. The
C<$slot_name> can optionally be specified, otherwise it will use the
name of the method that the trait is being applied to.

    sub foo : rw;
    sub foo : rw(_foo);

If the method name is prefixed with C<set_>, then this trait will
infer that the slot name intended is the remainder of the method's
name, minus the C<set_> prefix, such that this:

    sub set_foo : ro;

Is the equivalent of writing this:

    sub set_foo : ro(foo);

=item C<wo( ?$slot_name )>

This will generate a simple write-only accessor for a slot. The
C<$slot_name> can optionally be specified, otherwise it will use the
name of the method that the trait is being applied to.

    sub foo : wo;
    sub foo : wo(_foo);

If the method name is prefixed with C<set_>, then this trait will
infer that the slot name intended is the remainder of the method's
name, minus the C<set_> prefix, such that this:

    sub set_foo : wo;

Is the equivalent of writing this:

    sub set_foo : wo(foo);

=item C<predicate( ?$slot_name )>

This will generate a simple predicate method for a slot. The
C<$slot_name> can optionally be specified, otherwise it will use the
name of the method that the trait is being applied to.

    sub foo : predicate;
    sub foo : predicate(_foo);

If the method name is prefixed with C<has_>, then this trait will
infer that the slot name intended is the remainder of the method's
name, minus the C<has_> prefix, such that this:

    sub has_foo : predicate;

Is the equivalent of writing this:

    sub has_foo : predicate(foo);

=item C<clearer( ?$slot_name )>

This will generate a simple clearing method for a slot. The
C<$slot_name> can optionally be specified, otherwise it will use the
name of the method that the trait is being applied to.

    sub foo : clearer;
    sub foo : clearer(_foo);

If the method name is prefixed with C<clear_>, then this trait will
infer that the slot name intended is the remainder of the method's
name, minus the C<clear_> prefix, such that this:

    sub clear_foo : clearer;

Is the equivalent of writing this:

    sub clear_foo : clearer(foo);

=back

=cut
