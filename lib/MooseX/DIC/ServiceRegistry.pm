package MooseX::DIC::ServiceRegistry;

use Moose;
with 'MooseX::DIC::Loggable';

# InterfaceName -> EnvironmentName => ServiceMetadata
has metadata => ( is => 'ro', isa => 'HashRef[HashRef[MooseX::DIC::ServiceMetadata]]', default => sub { {} } );

# (:ServiceMetadata) -> Void
sub add_service_definition {
	my ($self,$service_metadata) = @_;

	my $interface_name = $service_metadata->implements;
	my $service_name = $service_metadata->class_name;
	my $environment = $service_metadata->environment;

	$self->logger->debug("Registering service $service_name for interface $interface_name ");
	
	if( exists $self->metadata->{$interface_name} ) {
		my $interface_definition = $self->metadata->{$interface_name};
		if(exists $interface_definition->{$environment}){
			if($interface_definition->{$environment}->class_name eq $service_name){
				$self->logger->warn("A definition was already found for $interface_name for the environment $environment, overwritting it");
			}
		}
		$interface_definition->{$environment} = $service_metadata;
	} else {
		$self->metadata->{$interface_name}->{$environment} = $service_metadata;
	}

	$self->logger->info("$service_name was registered as an implementation of $interface_name for environment $environment");
}

# (interface_name:Str[,environment:Str='default']) -> service:ServiceMetadata
sub get_service_definition {
	my ($self,$interface_name,$original_environment) = @_;
	my $environment = $original_environment || 'default';

	$self->logger->trace("An implementation for $interface_name was requested");
	my $service_definition;
	
	if( exists $self->metadata->{$interface_name} ) {
		$service_definition = $self->metadata->{$interface_name}->{$environment};
		# always try the default environment if the specified one didn't exist
		if(not(defined($service_definition)) and not($environment eq 'default')){
			$self->logger->trace("An implementation for $interface_name was not found in environment $environment, searching in default namespace");
			$service_definition = $self->metadata->{$interface_name}->{'default'};
			$self->logger->trace("The implementation for $interface_name was found in the default environment") if defined($service_definition);
		}

		$self->logger->debug("An implementation for $interface name was requested, but none have been declared")
			if(not(defined($service_definition)));
	} else {
		$self->logger->debug("An implementation for $interface_name was requested, but none have been declared");
	}

	return $service_definition;
}

#### Auxiliary functions
sub _build_env_index {
	# There's always a default environment
	return {
		default => {}
	};
}
1;
