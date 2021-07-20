# puppet-nm_connection

## examples

```
nm_connection { 'dummy0 connection':
# ensure       => absent,
  type         => 'dummy',
  interface    => 'dummy0',
  ipv4_options => {
    'method' => 'disabled',
  },
  ipv6_options => {
    'method' => 'disabled',
  }
}
```


```
nm_connection { 'dummy1 connection':
# ensure       => absent,
  type         => 'dummy',
  interface    => 'dummy1',
  ipv4_options => {
    'method'    => 'manual',
    'addresses' => '127.2.0.1/24'
  },
  ipv6_options => {
    'method' => 'disabled',
  }
}
```


```
nm_connection { 'ens3 connection':
# ensure       => absent,
  type         => '802-3-ethernet',
  interface    => 'ens3',
  ipv4_options => {
    'method' => 'auto',
  },
  ipv6_options => {
    'method' => 'auto',
  }
}
```
