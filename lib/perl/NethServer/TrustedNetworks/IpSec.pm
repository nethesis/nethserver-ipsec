#
# Copyright (C) 2015 Nethesis S.r.l.
# http://www.nethesis.it - nethserver@nethesis.it
#
# This script is part of NethServer.
#
# NethServer is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License,
# or any later version.
#
# NethServer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with NethServer.  If not, see COPYING.
#

use strict;

package NethServer::TrustedNetworks::IpSec;
use NethServer::TrustedNetworks qw(register_callback);
use esmith::DB::db;
use esmith::util;

register_callback(\&ipsec_networks);
register_callback(\&ipsec_tunnels);

#
# Push IPsec L2TP network
#
sub ipsec_networks
{
    my $results = shift;

    my $config_db = esmith::DB::db->open_ro('configuration');
    if( ! $config_db ) {
        return;
    }

    my $net = $config_db->get_prop('ipsec', 'L2tpNetwork') || '';
    my $msk = $config_db->get_prop('ipsec', 'L2tpNetmask') || '';

    my $cidr = esmith::util::computeLocalNetworkShortSpec($net, $msk);

    if($cidr) {
        push(@$results, {'cidr' => $cidr, 'provider' => 'IPsec'});
    }

}

#
# Push IPsec tunnel network
#
sub ipsec_tunnels
{
    my $results = shift;

    my $vpn_db = esmith::DB::db->open_ro('vpn');
    if (defined $vpn_db) {
      foreach ($vpn_db->get_all_by_prop('type' => 'ipsec-tunnel')) {
          my $subnets = $_->prop('rightsubnets') || 'next';
          foreach my $net (split(/,/, $subnets)) {
              push(@$results, {'cidr' => $net, 'provider' => 'IPsec'});
          }
      }
    }
}
