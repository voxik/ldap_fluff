require 'net/ldap'

# handles the naughty bits of posix ldap
class LdapFluff::Posix::MemberService

  attr_accessor :ldap

  def initialize(ldap,group_base)
    @ldap = ldap
    @group_base = group_base
  end

  # return an ldap user with groups attached
  # note : this method is not particularly fast for large ldap systems
  def find_user_groups(uid)
    groups = []
    @ldap.search(:filter => name_filter(uid), :base => @group_base).each do |entry|
      groups << entry[:cn][0]
    end
    groups
  end

  def times_in_groups(uid, gids, all)
    matches = 0
    filters = []
    gids.each do |cn|
      filters << group_filter(cn)
    end
    group_filters = merge_filters(filters,all)
    filter = name_filter(uid) & group_filters
    @ldap.search(:base => @group_base, :filter => filter).size
  end

  def name_filter(uid)
    Net::LDAP::Filter.eq("memberUid",uid)
  end

  def group_filter(cn)
    Net::LDAP::Filter.eq("cn", cn)
  end

  # AND or OR all of the filters together
  def merge_filters(filters = [], all=false)
    if filters != nil && filters.size >= 1
      filter = filters[0]
      filters[1..filters.size-1].each do |gfilter|
        if all
          filter = filter & gfilter
        else
          filter = filter | gfilter
        end
      end
      return filter
    end
  end
end
