Puppet::Type.newtype(:nm_connection) do
  ensurable
  newparam(:name, namevar: true) do
    desc "network manager connection name"
  end

  newproperty(:type) do
    desc "connection type"
  end

  newproperty(:interface) do
    desc "connection interface"
  end

  newproperty(:uuid) do
    desc "connection uuid (read-only)"
  end

  newproperty(:ipv4_options) do
    desc "ipv4 options for the connection"
    def insync?(is)
      return provider.option_insync?(is, @should, :ipv4_options)
    end

    def change_to_s(current, new)
      merged = current.merge(new)
      super(current, merged)
    end
  end

  newproperty(:ipv6_options) do
    desc "ipv6 options for the connection"
    def insync?(is)
      return provider.option_insync?(is, @should, :ipv6_options)
    end

    def change_to_s(current, new)
      merged = current.merge(new)
      super(current, merged)
    end
  end

end
