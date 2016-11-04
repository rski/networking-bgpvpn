#!/bin/bash

# Save trace setting
_XTRACE_NETWORKING_BGPVPN=$(set +o | grep xtrace)
set -o xtrace

if [[ "$1" == "source" ]]; then
    # no-op
    :
elif [[ "$1" == "stack" && "$2" == "install" ]]; then
    echo_summary "Installing networking-bgpvpn"
    setup_develop $NETWORKING_BGPVPN_DIR
elif [[ "$1" == "stack" && "$2" == "pre-install" ]]; then
    echo_summary "Enabling networking-bgpvpn service plugin"
    _neutron_service_plugin_class_add $BGPVPN_PLUGIN_CLASS
    if [[ "$Q_AGENT" == "bagpipe-openvswitch" ]]; then
        echo "networking-bagpipe: you don't need to set Q_AGENT=bagpipe-openvswitch anymore"
        Q_AGENT=openvswitch``
    fi
elif [[ "$1" == "stack" && "$2" == "extra" ]]; then
    if is_service_enabled tempest; then
        echo_summary "Enabling bgpvpn in $TEMPEST_CONFIG"
        iniset $TEMPEST_CONFIG service_available bgpvpn "True"
    fi
elif [[ "$1" == "stack" && "$2" == "post-config" ]]; then
    if is_service_enabled q-svc; then
        echo_summary "Configuring networking-bgpvpn"
        mkdir -v -p $NEUTRON_CONF_DIR/policy.d && cp -v $NETWORKING_BGPVPN_DIR/etc/neutron/policy.d/bgpvpn.conf $NEUTRON_CONF_DIR/policy.d
        mkdir -v -p $(dirname $NETWORKING_BGPVPN_CONF) && cp -v $NETWORKING_BGPVPN_DIR/etc/neutron/networking_bgpvpn.conf $NETWORKING_BGPVPN_CONF
        inicomment $NETWORKING_BGPVPN_CONF service_providers service_provider
        iniadd $NETWORKING_BGPVPN_CONF service_providers service_provider $NETWORKING_BGPVPN_DRIVER
    fi
    if is_service_enabled q-agt && is_service_enabled b-bgp && [[ "$Q_AGENT" == "openvswitch" ]]; then
        echo_summary "Configuring OVS agent for bagpipe"
        source $NEUTRON_DIR/devstack/lib/l2_agent
        plugin_agent_add_l2_agent_extension bagpipe_bgpvpn
        configure_l2_agent
    fi
    if is_service_enabled horizon; then
        cp $BGPVPN_DASHBOARD_ENABLE $HORIZON_DIR/openstack_dashboard/local/enabled/
    fi
fi
if [[ "$1" == "unstack" ]]; then
    #no-op
    :
fi
if [[ "$1" == "clean" ]]; then
    # Remove bgpvpn-dashboard enabled files and pyc
    rm -f $HORIZON_DIR/openstack_dashboard/local/enabled/*_bgpvpn_panel*
fi

# Restore XTRACE
${_XTRACE_NETWORKING_BGPVPN}

