# encoding: utf-8
# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'select input' do

  include FormtasticSpecHelper

  before do
    @output_buffer = ActiveSupport::SafeBuffer.new ''
    mock_everything
  end

  describe 'explicit values' do
    describe 'using an array of values' do
      before do
        @array_with_values = ["Title A", "Title B", "Title C"]
        @array_with_keys_and_values = [["Title D", 1], ["Title E", 2], ["Title F", 3]]
        concat(semantic_form_for(@new_post) do |builder|
          concat(builder.input(:title, :as => :select, :collection => @array_with_values))
          concat(builder.input(:title, :as => :select, :collection => @array_with_keys_and_values))
        end)
      end

      it 'should have a option for each key and/or value' do
        @array_with_values.each do |v|
          expect(output_buffer).to have_tag("form li select option[@value='#{v}']", :text => /^#{v}$/)
        end
        @array_with_keys_and_values.each do |v|
          expect(output_buffer).to have_tag("form li select option[@value='#{v.second}']", :text => /^#{v.first}$/)
        end
      end
    end
    
    describe 'using a set of values' do
      before do
        @set_with_values = Set.new(["Title A", "Title B", "Title C"])
        @set_with_keys_and_values = [["Title D", :d], ["Title E", :e], ["Title F", :f]]
        concat(semantic_form_for(@new_post) do |builder|
          concat(builder.input(:title, :as => :select, :collection => @set_with_values))
          concat(builder.input(:title, :as => :select, :collection => @set_with_keys_and_values))
        end)
      end

      it 'should have a option for each key and/or value' do
        @set_with_values.each do |v|
          expect(output_buffer).to have_tag("form li select option[@value='#{v}']", :text => /^#{v}$/)
        end
        @set_with_keys_and_values.each do |v|
          expect(output_buffer).to have_tag("form li select option[@value='#{v.second}']", :text => /^#{v.first}$/)
        end
      end
    end

    describe "using a related model without reflection's options (Mongoid Document)" do
      before do
        allow(@new_post).to receive(:mongoid_reviewer)
        concat(semantic_form_for(@new_post) do |builder|
          concat(builder.input(:mongoid_reviewer, :as => :select))
        end)
      end

      it 'should draw select options' do
        expect(output_buffer).to have_tag('form li select')
        expect(output_buffer).to have_tag('form li select#post_reviewer_id')
        expect(output_buffer).not_to have_tag('form li select#post_mongoid_reviewer_id')
      end
    end

    describe 'using a range' do
      before do
        @range_with_values = 1..5
        concat(semantic_form_for(@new_post) do |builder|
          concat(builder.input(:title, :as => :select, :collection => @range_with_values))
        end)
      end

      it 'should have an option for each value' do
        @range_with_values.each do |v|
          expect(output_buffer).to have_tag("form li select option[@value='#{v}']", :text => /^#{v}$/)
        end
      end
    end

    describe 'using a string' do
      before do
        @string ="<option value='0'>0</option><option value='1'>1</option>".html_safe
        concat(semantic_form_for(@new_post) do |builder|
          concat(builder.input(:title, :as => :select, :collection => @string))
        end)
      end

      it 'should render select options using provided HTML string' do
        2.times do |v|
          expect(output_buffer).to have_tag("form li select option[@value='#{v}']", :text => /^#{v}$/)
        end
      end
    end

    describe 'using a nil name' do
      before do
        concat(semantic_form_for(@new_post) do |builder|
          concat(builder.input(:title, :as => :select, :collection => [], :input_html => {:name => nil}))
        end)
      end

      it_should_have_select_with_name("post[title]")
    end
  end

  describe 'for boolean columns' do
    describe 'default formtastic locale' do
      before do
        # Note: Works, but something like Formtastic.root.join(...) would probably be "safer".
        ::I18n.load_path = [File.join(File.dirname(__FILE__), *%w[.. .. lib locale en.yml])]
        ::I18n.backend.send(:init_translations)

        concat(semantic_form_for(@new_post) do |builder|
          concat(builder.input(:published, :as => :select))
        end)
      end

      after do
        ::I18n.load_path = []
        ::I18n.backend.store_translations :en, {}
      end

      it 'should render a select with at least options: true/false' do
        expect(output_buffer).to have_tag("form li select option[@value='true']", :text => /^Yes$/)
        expect(output_buffer).to have_tag("form li select option[@value='false']", :text => /^No$/)
      end
    end

    describe 'custom locale' do
      before do
        @boolean_select_labels = {:yes => 'Yep', :no => 'Nope'}
        ::I18n.backend.store_translations :en, :formtastic => @boolean_select_labels

        concat(semantic_form_for(@new_post) do |builder|
          concat(builder.input(:published, :as => :select))
        end)
      end

      after do
        ::I18n.backend.store_translations :en, {}
      end

      it 'should render a select with at least options: true/false' do
        expect(output_buffer).to have_tag("form li select option[@value='true']", :text => /#{@boolean_select_labels[:yes]}/)
        expect(output_buffer).to have_tag("form li select option[@value='false']", :text => /#{@boolean_select_labels[:no]}/)
      end
    end
  end

  describe 'for a enum column' do
    before do
      allow(@new_post).to receive(:status) { 'inactive' }
      statuses = ActiveSupport::HashWithIndifferentAccess.new("active"=>0, "inactive"=>1)
      allow(@new_post.class).to receive(:statuses) { statuses }
      allow(@new_post).to receive(:defined_enums) { { "status" => statuses } }
    end

    context 'with translations in a nested association input' do
      before do
        ::I18n.backend.store_translations :en, activerecord: {
          attributes: {
            post: {
              statuses: {
                active: 'I am active',
                inactive: 'I am inactive'
              }
            }
          }
        }

        allow(@fred).to receive(:posts).and_return([@new_post])
        concat(semantic_form_for(@fred) do |builder|
          concat(builder.inputs(for: @fred.posts.first) do |nested_builder|
            nested_builder.input(:status, as: :select)
          end)
        end)
      end

      after do
        ::I18n.backend.reload!
      end

      it 'should use localized enum values' do
        expect(output_buffer).to have_tag("form li select option[@value='active']", text: 'I am active')
        expect(output_buffer).to have_tag("form li select option[@value='inactive']", text: 'I am inactive')
      end
    end

    context 'single choice' do
      before do
        concat(semantic_form_for(@new_post) do |builder|
          concat(builder.input(:status, :as => :select))
        end)
      end

      it_should_have_input_wrapper_with_class("select")
      it_should_have_input_wrapper_with_class(:input)
      it_should_have_input_wrapper_with_id("post_status_input")
      it_should_have_label_with_text(/Status/)
      it_should_have_label_for('post_status')
      it_should_apply_error_logic_for_input_type(:select)

      it 'should have a select inside the wrapper' do
        expect(output_buffer).to have_tag('form li select')
        expect(output_buffer).to have_tag('form li select#post_status')
      end

      it 'should have a valid name' do
        expect(output_buffer).to have_tag("form li select[@name='post[status]']")
        expect(output_buffer).not_to have_tag("form li select[@name='post[status][]']")
      end

      it 'should not create a multi-select' do
        expect(output_buffer).not_to have_tag('form li select[@multiple]')
      end
      
      it 'should not add a hidden input' do
        expect(output_buffer).not_to have_tag('form li input[@type="hidden"]')
      end

      it 'should create a select without size' do
        expect(output_buffer).not_to have_tag('form li select[@size]')
      end

      it 'should have a blank option' do
        expect(output_buffer).to have_tag("form li select option[@value='']")
      end

      it 'should have a select option for each defined enum status' do
        expect(output_buffer).to have_tag("form li select[@name='post[status]'] option", :count => @new_post.class.statuses.count + 1)
        @new_post.class.statuses.each do |label, value|
          expect(output_buffer).to have_tag("form li select option[@value='#{label}']", :text => /#{label.humanize}/)
        end
      end

      it 'should have one option with a "selected" attribute (TODO)' do
        expect(output_buffer).to have_tag("form li select[@name='post[status]'] option[@selected]", :count => 1)
      end
    end

    context 'multiple choice' do
      it 'raises an error' do
        expect {
          concat(semantic_form_for(@new_post) do |builder|
            concat(builder.input(:status, :as => :select, :multiple => true))
          end)
        }.to raise_error Formtastic::UnsupportedEnumCollection
      end
    end
  end

  describe 'for a belongs_to association' do
    before do
      concat(semantic_form_for(@new_post) do |builder|
        concat(builder.input(:author, :as => :select))
        concat(builder.input(:reviewer, :as => :select))
      end)
    end

    it_should_have_input_wrapper_with_class("select")
    it_should_have_input_wrapper_with_class(:input)
    it_should_have_input_wrapper_with_id("post_author_input")
    it_should_have_label_with_text(/Author/)
    it_should_have_label_for('post_author_id')
    it_should_apply_error_logic_for_input_type(:select)
    it_should_call_find_on_association_class_when_no_collection_is_provided(:select)
    it_should_use_the_collection_when_provided(:select, 'option')

    it 'should have a select inside the wrapper' do
      expect(output_buffer).to have_tag('form li select')
      expect(output_buffer).to have_tag('form li select#post_author_id')
      expect(output_buffer).to have_tag('form li select#post_reviewer_id')
    end

    it 'should have a valid name' do
      expect(output_buffer).to have_tag("form li select[@name='post[author_id]']")
      expect(output_buffer).not_to have_tag("form li select[@name='post[author_id][]']")
      expect(output_buffer).not_to have_tag("form li select[@name='post[reviewer_id][]']")
    end

    it 'should not create a multi-select' do
      expect(output_buffer).not_to have_tag('form li select[@multiple]')
    end
    
    it 'should not add a hidden input' do
      expect(output_buffer).not_to have_tag('form li input[@type="hidden"]')
    end

    it 'should create a select without size' do
      expect(output_buffer).not_to have_tag('form li select[@size]')
    end

    it 'should have a blank option' do
      expect(output_buffer).to have_tag("form li select option[@value='']")
    end

    it 'should have a select option for each Author' do
      expect(output_buffer).to have_tag("form li select[@name='post[author_id]'] option", :count => ::Author.all.size + 1)
      ::Author.all.each do |author|
        expect(output_buffer).to have_tag("form li select option[@value='#{author.id}']", :text => /#{author.to_label}/)
      end
    end

    it 'should have one option with a "selected" attribute (bob)' do
      expect(output_buffer).to have_tag("form li select[@name='post[author_id]'] option[@selected]", :count => 1)
    end

    it 'should not singularize the association name' do
      allow(@new_post).to receive(:author_status).and_return(@bob)
      allow(@new_post).to receive(:author_status_id).and_return(@bob.id)
      allow(@new_post).to receive(:column_for_attribute).and_return(double('column', :type => :integer, :limit => 255))

      concat(semantic_form_for(@new_post) do |builder|
        concat(builder.input(:author_status, :as => :select))
      end)

      expect(output_buffer).to have_tag('form li select#post_author_status_id')
    end
  end

  describe "for a belongs_to association with :conditions" do
    before do
      allow(::Post).to receive(:reflect_on_association).with(:author) do
        mock = double('reflection', :scope => nil, :options => {:conditions => {:active => true}}, :klass => ::Author, :macro => :belongs_to)
        allow(mock).to receive(:[]).with(:class_name).and_return("Author")
        mock
      end
    end

    it "should call author.where with association conditions" do
      expect(::Author).to receive(:where).with({:active => true})

      semantic_form_for(@new_post) do |builder|
        concat(builder.input(:author, :as => :select))
      end
    end
  end

  describe "for a belongs_to association with scope" do
    before do
      @active_scope = -> { active }
      allow(::Post).to receive(:reflect_on_association).with(:author) do
        mock = double('reflection', :scope => @active_scope, options: {}, :klass => ::Author, :macro => :belongs_to)
        allow(mock).to receive(:[]).with(:class_name).and_return("Author")
        mock
      end
    end

    it "should call author.merge with association scope" do
      expect(::Author).to receive(:merge).with(@active_scope)

      semantic_form_for(@new_post) do |builder|
        concat(builder.input(:author, :as => :select))
      end
    end
  end

  describe 'for a has_many association' do
    before do
      concat(semantic_form_for(@fred) do |builder|
        concat(builder.input(:posts, :as => :select))
      end)
    end

    it_should_have_input_wrapper_with_class("select")
    it_should_have_input_wrapper_with_id("author_posts_input")
    it_should_have_label_with_text(/Post/)
    it_should_have_label_for('author_post_ids')
    it_should_apply_error_logic_for_input_type(:select)
    it_should_call_find_on_association_class_when_no_collection_is_provided(:select)
    it_should_use_the_collection_when_provided(:select, 'option')

    it 'should have a select inside the wrapper' do
      expect(output_buffer).to have_tag('form li select')
      expect(output_buffer).to have_tag('form li select#author_post_ids')
    end

    it 'should have a multi-select select' do
      expect(output_buffer).to have_tag('form li select[@multiple="multiple"]')
    end
    
    it 'should append [] to the name attribute for multiple select' do
      expect(output_buffer).to have_tag('form li select[@multiple="multiple"][@name="author[post_ids][]"]')
    end

    it 'should have a hidden field' do
      expect(output_buffer).to have_tag('form li input[@type="hidden"][@name="author[post_ids][]"]', :count => 1)
    end

    it 'should have a select option for each Post' do
      expect(output_buffer).to have_tag('form li select option', :count => ::Post.all.size)
      ::Post.all.each do |post|
        expect(output_buffer).to have_tag("form li select option[@value='#{post.id}']", :text => /#{post.to_label}/)
      end
    end

    it 'should not have a blank option by default' do
      expect(output_buffer).not_to have_tag("form li select option[@value='']")
    end

    it 'should respect the :include_blank option for single selects' do
      concat(semantic_form_for(@fred) do |builder|
        concat(builder.input(:posts, :as => :select, :multiple => false, :include_blank => true))
      end)

      expect(output_buffer).to have_tag("form li select option[@value='']")
    end

    it 'should respect the :include_blank option for multiple selects' do
      concat(semantic_form_for(@fred) do |builder|
        concat(builder.input(:posts, :as => :select, :multiple => true, :include_blank => true))
      end)

      expect(output_buffer).to have_tag("form li select option[@value='']")
    end

    it 'should have one option with a "selected" attribute' do
      expect(output_buffer).to have_tag('form li select option[@selected]', :count => 1)
    end
  end

  describe 'for a has_and_belongs_to_many association' do
    before do
      concat(semantic_form_for(@freds_post) do |builder|
        concat(builder.input(:authors, :as => :select))
      end)
    end

    it_should_have_input_wrapper_with_class("select")
    it_should_have_input_wrapper_with_id("post_authors_input")
    it_should_have_label_with_text(/Author/)
    it_should_have_label_for('post_author_ids')
    it_should_apply_error_logic_for_input_type(:select)
    it_should_call_find_on_association_class_when_no_collection_is_provided(:select)
    it_should_use_the_collection_when_provided(:select, 'option')

    it 'should have a select inside the wrapper' do
      expect(output_buffer).to have_tag('form li select')
      expect(output_buffer).to have_tag('form li select#post_author_ids')
    end

    it 'should have a multi-select select' do
      expect(output_buffer).to have_tag('form li select[@multiple="multiple"]')
    end

    it 'should have a select option for each Author' do
      expect(output_buffer).to have_tag('form li select option', :count => ::Author.all.size)
      ::Author.all.each do |author|
        expect(output_buffer).to have_tag("form li select option[@value='#{author.id}']", :text => /#{author.to_label}/)
      end
    end

    it 'should not have a blank option by default' do
      expect(output_buffer).not_to have_tag("form li select option[@value='']")
    end

    it 'should respect the :include_blank option for single selects' do
      concat(semantic_form_for(@freds_post) do |builder|
        concat(builder.input(:authors, :as => :select, :multiple => false, :include_blank => true))
      end)

      expect(output_buffer).to have_tag("form li select option[@value='']")
    end

    it 'should respect the :include_blank option for multiple selects' do
      concat(semantic_form_for(@freds_post) do |builder|
        concat(builder.input(:authors, :as => :select, :multiple => true, :include_blank => true))
      end)

      expect(output_buffer).to have_tag("form li select option[@value='']")
    end

    it 'should have one option with a "selected" attribute' do
      expect(output_buffer).to have_tag('form li select option[@selected]', :count => 1)
    end
  end

  describe 'when :prompt => "choose something" is set' do
    before do
      allow(@new_post).to receive(:author_id).and_return(nil)
      concat(semantic_form_for(@new_post) do |builder|
        concat(builder.input(:author, :as => :select, :prompt => "choose author"))
      end)
    end

    it 'should have a select with prompt' do
      expect(output_buffer).to have_tag("form li select option[@value='']", :text => /choose author/, :count => 1)
    end

    it 'should not have a second blank select option' do
      expect(output_buffer).to have_tag("form li select option[@value='']", :count => 1)
    end
  end

  describe 'when no object is given' do
    before(:example) do
      concat(semantic_form_for(:project, :url => 'http://test.host') do |builder|
        concat(builder.input(:author, :as => :select, :collection => ::Author.all))
      end)
    end

    it 'should generate label' do
      expect(output_buffer).to have_tag('form li label', :text => /Author/)
      expect(output_buffer).to have_tag("form li label[@for='project_author']")
    end

    it 'should generate select inputs' do
      expect(output_buffer).to have_tag('form li select#project_author')
      expect(output_buffer).to have_tag('form li select option', :count => ::Author.all.size + 1)
    end

    it 'should generate an option to each item' do
      ::Author.all.each do |author|
        expect(output_buffer).to have_tag("form li select option[@value='#{author.id}']", :text => /#{author.to_label}/)
      end
    end
  end

  describe 'when no association exists' do

    it 'should still generate a valid name attribute' do
      concat(semantic_form_for(:project, :url => 'http://test.host') do |builder|
        concat(builder.input(:author_name, :as => :select, :collection => ::Author.all))
      end)
      expect(output_buffer).to have_tag("form li select[@name='project[author_name]']")
    end

    describe 'and :multiple is set to true through :input_html' do
      it "should make the select a multi-select" do
        concat(semantic_form_for(:project, :url => 'http://test.host') do |builder|
          concat(builder.input(:author_name, :as => :select, :input_html => {:multiple => true} ))
        end)
        expect(output_buffer).to have_tag("form li select[@multiple]")
      end
    end

    describe 'and :multiple is set to true' do
      it "should make the select a multi-select" do
        concat(semantic_form_for(:project, :url => 'http://test.host') do |builder|
          concat(builder.input(:author_name, :as => :select, :multiple => true, :collection => ["Fred", "Bob"]))
        end)
        expect(output_buffer).to have_tag("form li select[@multiple]")
      end
    end

  end

  describe 'when a grouped collection collection is given' do
    before(:example) do
      concat(semantic_form_for(:project, :url => 'http://test.host') do |builder|
        @grouped_opts = [['one',   ['pencil', 'crayon', 'pen']],
                         ['two',   ['eyes', 'hands', 'feet']],
                         ['three', ['wickets', 'witches', 'blind mice']]]
        concat(builder.input(:author, :as => :select, :collection => grouped_options_for_select(@grouped_opts, "hands")))
      end)
    end

    it 'should generate an option to each item' do
      @grouped_opts.each do |opt_pair|
        expect(output_buffer).to have_tag("form li select optgroup[@label='#{opt_pair[0]}']")
        opt_pair[1].each do |v|
          expect(output_buffer).to have_tag("form li select optgroup[@label='#{opt_pair[0]}'] option[@value='#{v}']")
        end
      end
      expect(output_buffer).to have_tag("form li select optgroup option[@selected]","hands")
    end
  end

  describe "enum" do
    before do
      @output_buffer = ActiveSupport::SafeBuffer.new ''
      @some_meta_descriptions = ["One", "Two", "Three"]
      allow(@new_post).to receive(:meta_description).at_least(:once)
    end

    describe ":as is not set" do
      before do
        concat(semantic_form_for(@new_post) do |builder|
          concat(builder.input(:meta_description, :collection => @some_meta_descriptions))
        end)
        concat(semantic_form_for(:project, :url => 'http://test.host') do |builder|
          concat(builder.input(:meta_description, :collection => @some_meta_descriptions))
        end)
      end

      it "should render a select field" do
        expect(output_buffer).to have_tag("form li select", :count => 2)
      end
    end

    describe ":as is set" do
      before do
        # Should not be a case, but just checking :as got highest priority in setting input type.
        concat(semantic_form_for(@new_post) do |builder|
          concat(builder.input(:meta_description, :as => :string, :collection => @some_meta_descriptions))
        end)
        concat(semantic_form_for(:project, :url => 'http://test.host') do |builder|
          concat(builder.input(:meta_description, :as => :string, :collection => @some_meta_descriptions))
        end)
      end

      it "should render a text field" do
        expect(output_buffer).to have_tag("form li input[@type='text']", :count => 2)
      end
    end
  end

  describe 'when a namespace is provided' do
    before do
      concat(semantic_form_for(@freds_post, :namespace => 'context2') do |builder|
        concat(builder.input(:authors, :as => :select))
      end)
    end
    it_should_have_input_wrapper_with_id("context2_post_authors_input")
    it_should_have_select_with_id("context2_post_author_ids")
    it_should_have_label_for("context2_post_author_ids")
  end
  
  describe "when index is provided" do
  
    before do
      @output_buffer = ActiveSupport::SafeBuffer.new ''
      mock_everything
  
      concat(semantic_form_for(@new_post) do |builder|
        concat(builder.fields_for(:author, :index => 3) do |author|
          concat(author.input(:name, :as => :select))
        end)
      end)
    end
    
    it 'should index the id of the wrapper' do
      expect(output_buffer).to have_tag("li#post_author_attributes_3_name_input")
    end
    
    it 'should index the id of the select tag' do
      expect(output_buffer).to have_tag("select#post_author_attributes_3_name")
    end
    
    it 'should index the name of the select' do
      expect(output_buffer).to have_tag("select[@name='post[author_attributes][3][name]']")
    end
    
  end

  context "when required" do
    it "should add the required attribute to the select's html options" do
      with_config :use_required_attribute, true do
        concat(semantic_form_for(@new_post) do |builder|
          concat(builder.input(:author, :as => :select, :required => true))
        end)
        expect(output_buffer).to have_tag("select[@required]")
      end
    end
  end

end
