# Ce trebuie sa faca:
# Defineste un nod ca fiind gestionat de vyatta

class vyatta($version=$vyatta::params::version) inherits vyatta::params {

    package { vyatta-version:
		ensure => $version
    }

}