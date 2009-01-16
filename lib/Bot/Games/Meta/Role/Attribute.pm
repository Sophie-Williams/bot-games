#!/usr/bin/perl
package Bot::Games::Meta::Role::Attribute;
use Moose::Role;

use Bot::Games::Meta::Method::Accessor::Command;

has command => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

around accessor_metaclass => sub {
    my $orig = shift;
    my $self = shift;
    return $self->command ? 'Bot::Games::Meta::Method::Accessor::Command'
                          : $self->$orig(@_);
};

after install_accessors => sub {
    my $self = shift;
    return unless $self->command;
    my $method_meta = $self->get_read_method_ref;
    $method_meta->pass_args(0);
};

no Moose::Role;

1;