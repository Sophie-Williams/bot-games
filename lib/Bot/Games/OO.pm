#!/usr/bin/perl
package Bot::Games::OO;
use Moose ();
use Moose::Exporter;
use Moose::Util::MetaRole;

sub command {
    my $class = shift;
    my ($name, $code) = @_;
    my $superclass = Moose::blessed($class->meta->get_method($name))
                  || 'Moose::Meta::Method';
    my $method_metaclass = Moose::Meta::Class->create_anon_class(
        superclasses => [$superclass],
        roles        => ['Bot::Games::Meta::Role::Command'],
        cache        => 1,
    );
    if (my $method_meta = $class->meta->get_method($name)) {
        $method_metaclass->rebless_instance($method_meta);
    }
    else {
        my $method_meta = $method_metaclass->name->wrap(
            $code,
            package_name => $class,
            name         => $name,
        );
        $class->meta->add_method($name, $method_meta);
    }
}

Moose::Exporter->setup_import_methods(
    with_caller => ['command'],
    also        => ['Moose'],
);

sub init_meta {
    shift;
    my %options = @_;
    Moose->init_meta(%options);
    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class                 => $options{for_class},
        attribute_metaclass_roles => ['Bot::Games::Meta::Role::Attribute'],
        metaclass_roles           => ['Bot::Games::Meta::Role::Class'],
    );
    return $options{for_class}->meta;
}

1;
