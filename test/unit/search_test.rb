require File.dirname(__FILE__) + '/../test_helper'

class SearchTest < ActiveSupport::TestCase
  fixtures :people, :families
  
  def setup
    Person.logged_in = people(:jeremy)
  end

  [
    [:name,        'tim',              1],
    [:birthday,    {:month => '4'},    2],
    [:birthday,    {:day => '24'},     2],
    [:anniversary, {:month => '8'},    1],
    [:anniversary, {:day => '11'},     1],
    [:address,     {:city => 'tulsa'}, 2],
    [:address,     {:state => 'ok'},   4],
    [:address,     {:zip => '74111'},  2],
    [:type,        'member',           5],
    [:type,        'staff',            2],
    [:type,        'deacon',           1],
    [:type,        'elder',            0]
  ].each do |attr, value, count|
    class_eval <<-END
      def test_#{attr}_#{value.is_a?(Hash) ? value.keys.first : value}
        @search = Search.new
        @search.#{attr} = #{value.inspect}
        assert_equal #{count}, @search.query.length
      end
    END
  end

  def test_search_children
    @search = Search.new
    @search.name = 'mac'
    assert_equal 0, @search.query.length
    people(:mac).update_attribute :parental_consent, Date.today.to_s
    results = @search.query
    assert_equal 1, results.length
    assert_equal 'Mac Morgan', results.first.name
  end

end
