module: buddha
author: Hannes Mehnert <hannes@mehnert.org>

define class <host> (<object>)
  slot host-name :: <string>, init-keyword: name:;
  slot host-ipv4-address :: <ip-address>, required-init-keyword: ip:;
  slot host-net :: <subnet>, init-keyword: net:;
  slot host-mac :: <mac-address>, init-keyword: mac:;
  slot host-zone :: <zone>, init-keyword: zone:;
end;

define method make (host == <host>,
                    #next next-method,
                    #rest rest,
                    #key ip,
                    #all-keys) => (res :: <host>)
  let args = rest;
  if (instance?(ip, <string>))
    args := exclude(args, #"ip");
    ip := make(<ip-address>, data: ip);
  end;
  apply(next-method, host, ip: ip, args);
end method;

define method print-object (host :: <host>, stream :: <stream>)
 => ()
  format(stream, "Host %s Zone %s Mac %s\n",
         host.host-name,
         host.host-zone.zone-name,
         as(<string>, host.host-mac));
  format(stream, "IP %s Net %s\n",
         as(<string>, host.host-ipv4-address),
         as(<string>, host.host-net.network-cidr));
end;

define method \< (a :: <host>, b :: <host>) => (res :: <boolean>)
  a.host-ipv4-address < b.host-ipv4-address
end;

define method as (class == <string>, host :: <host>)
 => (res :: <string>)
  concatenate(host.host-name, " ", as(<string>, host.host-ipv4-address));
end;

define method gen-xml (host :: <host>)
  with-xml()
    tr
    {
      td(host.host-name),
      td(as(<string>, host.host-ipv4-address)),
      td(as(<string>, host.host-net.network-cidr)),
      td(as(<string>, host.host-mac)),
      td(host.host-zone.zone-name)
    }
  end;
end;

define method print-isc-dhcpd-file (host :: <host>, stream :: <stream>)
 => ()
  format(stream, "host %s {\n", host.host-name);
  format(stream, "\thardware ethernet %s;\n", as(<string>, host.host-mac));
  format(stream, "\tfixed-address %s;\n", as(<string>, host.host-ipv4-address));
  format(stream, "}\n\n");
end;

