use MooseX::Declare;

class Bennu::MOP::Mu {
    has how => (is => 'rw');
    has who => (is => 'rw');
    has defined => (is => 'rw');
}

class Bennu::MOP::Scope extends Bennu::MOP::Mu {
    has outer => (is => 'ro');
}

class Bennu::MOP::Package extends Bennu::MOP::Mu {
    has name => (is => 'ro');
    has static_definitions => (is => 'ro', default => sub { {} });
    has static_names => (is => 'ro', default => sub { {} });

    method type { 'package' }

    method assign_static($name, $value) {
        if (@$name == 1) {
            $self->static_names->{$name->[0]} = 1;
            $self->static_definitions->{$name->[0]} = $value;
        } elsif (exists $self->static_definitions->{$name->[0]}) {
            my $child = $self->static_definitions->{$name->[0]};
            my $name_length = scalar @$name;
            my @remaining = $name->[1 .. $name_length - 1];
            $child->assign_static(\@remaining, $value);
        } else {
            die "Attempted to assign to non-existent package " .
              $self->name . '::' . $name->[0] . ".";
        }
    }
}

class Bennu::MOP::ClassWHAT extends Bennu::MOP::Mu {
}

class Bennu::MOP::ClassHOW extends Bennu::MOP::Mu {
    has _name => (is => 'rw', init_arg => 'name');
    has _attributes => (is => 'ro', init_arg => 'attributes',
                       default => sub { [] });
    has _methods => (is => 'ro', init_arg => 'methods',
                     default => sub { [] });
    has _instance_repr => (is => 'rw', init_arg => 'instance_repr');

    method BUILD ($args) {
        $self->_instance_repr($self->_instance_repr->new(class => $self));
    }

    method new_type_object() {
        $self->_instance_repr->create_type_object($self);
    }

    method add_attribute($obj, $attribute) {
        return $obj->how->add_attribute($obj, $attribute)
          unless $obj->how == $self;
        push @{ $self->_attributes }, $attribute;
        $self->_instance_repr->add_attribute($attribute);
    }

    method add_method($obj, $method) {
        return $obj->how->add_method($obj, $method)
          unless $obj->how == $self;
        push @{ $self->_methods }, $method;
    }
}

class Bennu::MOP::Attribute extends Bennu::MOP::Mu {
    has name => (is => 'ro');
    has private => (is => 'ro', isa => 'Bool');
    has constraints => (is => 'ro', default => sub { [] });
    has traits => (is => 'ro', default => sub { [] });
}

class Bennu::MOP::Method extends Bennu::MOP::Scope {
    has name => (is => 'ro');
    has body => (is => 'rw');
    has traits => (is => 'ro', default => sub { [] });
}

class Bennu::MOP::REPR extends Bennu::MOP::Mu {
    has class => (is => 'ro'); # the how the repr is associated with.
}

class Bennu::MOP::P6opaqueREPR extends Bennu::MOP::REPR {
}

class Bennu::MOP::LLClassREPR extends Bennu::MOP::REPR {
    has _attributes => (is => 'ro', default => sub { [] });

    method create_type_object($how) {
        Bennu::MOP::ClassWHAT->new(how => $how, repr => $self, defined => 0);
    }

    method add_attribute($attribute) {
        push @{ $self->_attributes }, $attribute;
    }
}
