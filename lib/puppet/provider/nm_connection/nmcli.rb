Puppet::Type.type(:nm_connection).provide(:nm_connection, parent: Puppet::Provider) do

  desc "manage nm connection"
  commands :nmcli => 'nmcli'

  def self.get_connection_list
    connections = nmcli('-t', '-f', 'UUID', 'connection', 'show')
    connections.strip!
    connections.split("\n")
  end

  def self.get_connection_properties(uuid)
    details = nmcli('-t', 'connection', 'show', uuid)
    details.strip!
    props = {}
    details.split("\n") do |prop|
      prop.strip!
      k, v = prop.split(':', 2)
      # skip if there's no value. e.g. is ''
      next if v == ''

      # TODO(mwhahaha): support array items
      section, option = k.split('.', 2)
      if option.nil?
        props[k] = v
      else
        if ! props.has_key?(section)
          props[section] = {}
        end
        props[section][option] = v
      end
    end
    props
  end

  def self.cache
    @cache || []
  end

  def self.set_cache(val)
    @cache = val
  end

  def self.instances
    inst = []
    get_connection_list.collect do |uuid|
      props = get_connection_properties(uuid)
      conn_props = props['connection'] || {}
      properties = {
        name: conn_props['id'],
        uuid: conn_props['uuid'],
        interface: conn_props['interface-name'],
        type: conn_props['type'], 
      }
      if props.has_key?('ipv4')
        properties[:ipv4_options] = props['ipv4']
      end
      if props.has_key?('ipv6')
        properties[:ipv6_options] = props['ipv6']
      end
      inst << new(properties)
    end
    inst
  end

  def self.prefetch(resources)
    connections = instances
    resources.keys.each do |conn_name|
      if provider = connections.find { |conn| conn.name == conn_name }
        resources[conn_name].provider = provider
      end
    end
    set_cache(connections)
  end

  def self.initvars
    puts('inivars')
    super
  end
  initvars

  def exists?
    return ! @property_hash[:uuid].nil?
  end

  def create
    name         = @resource.value(:name)
    interface    = @resource.value(:interface)
    type         = @resource.value(:type)
    ipv4_options = @resource.value(:ipv4_options) || nil
    ipv6_options = @resource.value(:ipv6_options) || nil
    @property_hash[:ensure] = :present

    cli_options = [
      'connection', 'add',
      'type', type,
      'connection.interface', interface,
      'con-name', name
    ]
    if ! ipv4_options.nil?
      ipv4_options.each do |k, v|
        cli_options.append("ipv4.#{k}", v) if v != ''
      end
      @property_hash[:ipv4_options] = ipv4_options
    end
    if ! ipv6_options.nil?
      ipv6_options.each do |k, v|
        cli_options.append("ipv6.#{k}", v) if v != ''
      end
      @property_hash[:ipv6_options] = ipv6_options
    end
    nmcli(cli_options)
    return exists?

  end

  def destroy
    if ! @property_hash[:uuid].nil?
      nmcli('-t', 'connection', 'delete', @property_hash[:uuid])
    end
    @property_hash.clear
    return exists?
  end

  mk_resource_methods

  def read_only(value)
    fail("This is a read-only property")
  end

  def diff_options(option, new)
    # use to diff complex dict options hash
    current = @property_hash[option]
    diff = new.keep_if { |k, v| current[k] != v }
    return diff
  end


  alias :uuid= :read_only

  def type=(string)
    @property_hash[:pending_update] = true
    return true
  end

  def interface=(string)
    @property_hash[:pending_update] = true
    return true
  end

  def ipv4_options=(hash)
    if diff_options(:ipv4_options, hash).empty?
      return false
    end
    @property_hash[:pending_update] = true
    return true

  end

  def ipv6_options=(hash)
    if diff_options(:ipv6_options, hash).empty?
      return false
    end
    @property_hash[:pending_update] = true
    return true
  end

  def option_insync?(current, should, option)
    debug("Checking if #{option} is insync")
    debug("current: #{current}")
    debug("should: #{should}")

    diff = should[0].keep_if { |k, v| current[k] != v}

    debug("diff: #{diff}")
    return diff.length == 0
  end

  def get_diff_options
    updates = []

    if @property_hash[:type] != @resource[:type]
      updates.append("connection.type", @resource[:type])
    end
    if @property_hash[:interface] != @resource[:interface]
      updates.append("connection.interface", @resource[:interface])
    end

    updateable = {
      :ipv4_options => 'ipv4', 
      :ipv6_options => 'ipv6', 
    }
    updateable.each do |opt, section|
      prop_opt = @property_hash[opt] || {}
      diff = @resource[opt].keep_if { |k, v| prop_opt[k] != v }
      diff.each do |k, v|
        # remove previous value if new has been set to ''
        if v == ''
          updates.append("-#{section}.#{k}", prop_opt[k])
        else
          updates.append("#{section}.#{k}", v)
        end
      end
    end
    updates
  end

  def update
    # was new, just bail
    debug('update...')
    return if @property_hash[:uuid].nil?
    update_args = [
      '-t', 'connection', 'modify', @property_hash[:uuid]
    ]
    update_args << get_diff_options
    nmcli('connection', 'down', @property_hash[:uuid])
    nmcli(update_args)
    nmcli('connection', 'up', @property_hash[:uuid])
  end

  def flush
    debug('flush....')
    if @property_hash.delete(:pending_update)
      update
    end
  end
end
