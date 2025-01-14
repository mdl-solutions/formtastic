# encoding: utf-8
# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'InputAction::Base' do
  
  # Most basic Action class to test Base
  class ::GenericAction
    include ::Formtastic::Actions::Base
    
    def supported_methods
      [:submit, :reset, :cancel]
    end
    
    def to_html
      wrapper do
        builder.submit(text, button_html)
      end
    end
  end
  
  include FormtasticSpecHelper

  before do
    @output_buffer = ActiveSupport::SafeBuffer.new ''
    mock_everything
  end
  
  describe 'wrapping HTML' do
    
    before do
      concat(semantic_form_for(@new_post) do |builder|
        concat(builder.action(:submit, :as => :generic,
          :wrapper_html => { :foo => 'bah' }
        ))
      end)
    end
    
    it 'should add the #foo id to the li' do
      expect(output_buffer).to have_tag('li#post_submit_action')
    end
    
    it 'should add the .action and .generic_action classes to the li' do
      expect(output_buffer).to have_tag('li.action.generic_action')
    end

    it 'should pass :wrapper_html HTML attributes to the wrapper' do
      expect(output_buffer).to have_tag('li.action.generic_action[@foo="bah"]')
    end
    
    context "when a custom :id is provided" do
      
      before do
        concat(semantic_form_for(@new_post) do |builder|
          concat(builder.action(:submit, :as => :generic, 
            :wrapper_html => { :id => 'foo_bah_bing' }
          ))
        end)
      end
      
      it "should use the custom id" do
        expect(output_buffer).to have_tag('li#foo_bah_bing')
      end
      
    end
    
    context "when a custom class is provided as a string" do 
      
      before do
        concat(semantic_form_for(@new_post) do |builder|
          concat(builder.action(:submit, :as => :generic, 
            :wrapper_html => { :class => 'foo_bah_bing' }
          ))
        end)
      end
      
      it "should add the custom class strng to the existing classes" do
        expect(output_buffer).to have_tag('li.action.generic_action.foo_bah_bing')
      end
      
    end
    
    context "when a custom class is provided as an array" do 
      
      before do
        concat(semantic_form_for(@new_post) do |builder|
          concat(builder.action(:submit, :as => :generic, 
            :wrapper_html => { :class => ['foo_bah_bing', 'zing_boo'] }
          ))
        end)
      end
      
      it "should add the custom class strng to the existing classes" do
        expect(output_buffer).to have_tag('li.action.generic_action.foo_bah_bing.zing_boo')
      end
      
    end
    
  end
  
  describe 'button HTML' do
    
    before do
      concat(semantic_form_for(@new_post) do |builder|
        concat(builder.action(:submit, :as => :generic, 
          :button_html => { :foo => 'bah' }
        ))
      end)
    end
    
    it 'should pass :button_html HTML attributes to the button' do
      expect(output_buffer).to have_tag('li.action.generic_action input[@foo="bah"]')
    end
    
    it 'should respect a default_commit_button_accesskey configuration with nil' do
      with_config :default_commit_button_accesskey, nil do
        concat(semantic_form_for(@new_post) do |builder|
          concat(builder.action(:submit, :as => :generic))
        end)
        expect(output_buffer).not_to have_tag('li.action input[@accesskey]')
      end
    end
    
    it 'should respect a default_commit_button_accesskey configuration with a String' do
      with_config :default_commit_button_accesskey, 's' do
        concat(semantic_form_for(@new_post) do |builder|
          concat(builder.action(:submit, :as => :generic))
        end)
        expect(output_buffer).to have_tag('li.action input[@accesskey="s"]')
      end
    end
    
    it 'should respect an accesskey through options over configration' do
      with_config :default_commit_button_accesskey, 's' do
        concat(semantic_form_for(@new_post) do |builder|
          concat(builder.action(:submit, :as => :generic, :accesskey => 'o'))
        end)
        expect(output_buffer).not_to have_tag('li.action input[@accesskey="s"]')
        expect(output_buffer).to have_tag('li.action input[@accesskey="o"]')
      end
    end
    
  end
    
  describe 'labelling' do
  
    describe 'when used without object' do
      
      describe 'when explicit label is provided' do
        it 'should render an input with the explicitly specified label' do
          concat(semantic_form_for(:post, :url => 'http://example.com') do |builder|
            concat(builder.action(:submit, :as => :generic, :label => "Click!"))
            concat(builder.action(:reset,  :as => :generic, :label => "Reset!"))
            concat(builder.action(:cancel, :as => :generic, :label => "Cancel!"))
          end)
          expect(output_buffer).to have_tag('li.generic_action input[@value="Click!"]')
          expect(output_buffer).to have_tag('li.generic_action input[@value="Reset!"]')
          expect(output_buffer).to have_tag('li.generic_action input[@value="Cancel!"]')
        end
      end
  
      describe 'when no explicit label is provided' do
        describe 'when no I18n-localized label is provided' do
          before do
            ::I18n.backend.store_translations :en, :formtastic => {
              :submit => 'Submit %{model}',
              :reset => 'Reset %{model}',
              :cancel => 'Cancel %{model}',
              :actions => {
                :message => {
                  :submit => 'Submit message',
                  :reset => 'Reset message',
                  :cancel => 'Cancel message'
                }
              }
            }
          end
  
          after do
            ::I18n.backend.reload!
          end
  
          it 'should render an input with default I18n-localized label (fallback)' do
            concat(semantic_form_for(:post, :url => 'http://example.com') do |builder|
              concat(builder.action(:submit, :as => :generic))
              concat(builder.action(:reset, :as => :generic))
              concat(builder.action(:cancel, :as => :generic))
            end)
            expect(output_buffer).to have_tag('li.generic_action input[@value="Submit Post"]')
            expect(output_buffer).to have_tag('li.generic_action input[@value="Cancel Post"]')
            expect(output_buffer).to have_tag('li.generic_action input[@value="Reset Post"]')
          end

          it 'should render an input with custom resource name localized label' do
            concat(semantic_form_for(:post, :as => :message, :url => 'http://example.com') do |builder|
              concat(builder.action(:submit, :as => :generic))
              concat(builder.action(:reset, :as => :generic))
              concat(builder.action(:cancel, :as => :generic))
            end)
            expect(output_buffer).to have_tag('li.generic_action input[@value="Submit message"]')
            expect(output_buffer).to have_tag('li.generic_action input[@value="Cancel message"]')
            expect(output_buffer).to have_tag('li.generic_action input[@value="Reset message"]')
          end
        end
  
       describe 'when I18n-localized label is provided' do
         
         before do
           ::I18n.backend.store_translations :en,
             :formtastic => {
                 :actions => {
                   :submit => 'Custom Submit',
                   :reset => 'Custom Reset',
                   :cancel => 'Custom Cancel'
                  }
               }
         end
  
         after do
           ::I18n.backend.reload!
         end
  
         it 'should render an input with localized label (I18n)' do
           with_config :i18n_lookups_by_default, true do
             ::I18n.backend.store_translations :en,
               :formtastic => {
                   :actions => {
                     :post => {
                       :submit => 'Custom Submit %{model}',
                       :reset => 'Custom Reset %{model}',
                       :cancel => 'Custom Cancel %{model}'
                      }
                    }
                 }

             concat(semantic_form_for(:post, :url => 'http://example.com') do |builder|
               concat(builder.action(:submit, :as => :generic))
               concat(builder.action(:reset, :as => :generic))
               concat(builder.action(:cancel, :as => :generic))
             end)
             expect(output_buffer).to have_tag(%Q{li.generic_action input[@value="Custom Submit Post"]})
             expect(output_buffer).to have_tag(%Q{li.generic_action input[@value="Custom Reset Post"]})
             expect(output_buffer).to have_tag(%Q{li.generic_action input[@value="Custom Cancel Post"]})
           end
         end
  
         it 'should render an input with anoptional localized label (I18n) - if first is not set' do
           with_config :i18n_lookups_by_default, true do
             concat(semantic_form_for(:post, :url => 'http://example.com') do |builder|
               concat(builder.action(:submit, :as => :generic))
               concat(builder.action(:reset, :as => :generic))
               concat(builder.action(:cancel, :as => :generic))
             end)
             expect(output_buffer).to have_tag(%Q{li.generic_action input[@value="Custom Submit"]})
             expect(output_buffer).to have_tag(%Q{li.generic_action input[@value="Custom Reset"]})
             expect(output_buffer).to have_tag(%Q{li.generic_action input[@value="Custom Cancel"]})
           end
         end
  
       end
      end
    end
  
    describe 'when used on a new record' do
      before do
        allow(@new_post).to receive(:new_record?).and_return(true)
      end
  
      describe 'when explicit label is provided' do
        it 'should render an input with the explicitly specified label' do
          concat(semantic_form_for(@new_post) do |builder|
            concat(builder.action(:submit, :as => :generic, :label => "Click!"))
            concat(builder.action(:reset, :as => :generic, :label => "Reset!"))
            concat(builder.action(:cancel, :as => :generic, :label => "Cancel!"))
          end)
          expect(output_buffer).to have_tag('li.generic_action input[@value="Click!"]')
          expect(output_buffer).to have_tag('li.generic_action input[@value="Reset!"]')
          expect(output_buffer).to have_tag('li.generic_action input[@value="Cancel!"]')
        end
      end
  
      describe 'when no explicit label is provided' do
        describe 'when no I18n-localized label is provided' do
          before do
            ::I18n.backend.store_translations :en, :formtastic => {
              :create => 'Create %{model}',
              :reset  => 'Reset %{model}',
              :cancel => 'Cancel %{model}'
            }
          end
  
          after do
            ::I18n.backend.reload!
          end
  
          it 'should render an input with default I18n-localized label (fallback)' do
            concat(semantic_form_for(@new_post) do |builder|
              concat(builder.action(:submit, :as => :generic))
              concat(builder.action(:reset,  :as => :generic))
              concat(builder.action(:cancel,  :as => :generic))
            end)
            expect(output_buffer).to have_tag('li.generic_action input[@value="Create Post"]')
            expect(output_buffer).to have_tag('li.generic_action input[@value="Reset Post"]')
            expect(output_buffer).to have_tag('li.generic_action input[@value="Cancel Post"]')
          end
        end
  
        describe 'when I18n-localized label is provided' do
          before do
            ::I18n.backend.store_translations :en,
              :formtastic => {
                  :actions => {
                    :create => 'Custom Create',
                    :reset => 'Custom Reset',
                    :cancel => 'Custom Cancel'
                   }
                }
          end
  
          after do
            ::I18n.backend.reload!
          end
  
          it 'should render an input with localized label (I18n)' do
            with_config :i18n_lookups_by_default, true do
              ::I18n.backend.store_translations :en,
                :formtastic => {
                    :actions => {
                      :post => {
                        :create => 'Custom Create %{model}',
                        :reset => 'Custom Reset %{model}',
                        :cancel => 'Custom Cancel %{model}'
                       }
                     }
                  }
              concat(semantic_form_for(@new_post) do |builder|
                concat(builder.action(:submit, :as => :generic))
                concat(builder.action(:reset, :as => :generic))
                concat(builder.action(:cancel, :as => :generic))
              end)
              expect(output_buffer).to have_tag(%Q{li.generic_action input[@value="Custom Create Post"]})
              expect(output_buffer).to have_tag(%Q{li.generic_action input[@value="Custom Reset Post"]})
              expect(output_buffer).to have_tag(%Q{li.generic_action input[@value="Custom Cancel Post"]})
            end
          end
  
          it 'should render an input with anoptional localized label (I18n) - if first is not set' do
            with_config :i18n_lookups_by_default, true do
              concat(semantic_form_for(@new_post) do |builder|
                concat(builder.action(:submit, :as => :generic))
                concat(builder.action(:reset, :as => :generic))
                concat(builder.action(:cancel, :as => :generic))
              end)
              expect(output_buffer).to have_tag(%Q{li.generic_action input[@value="Custom Create"]})
              expect(output_buffer).to have_tag(%Q{li.generic_action input[@value="Custom Reset"]})
              expect(output_buffer).to have_tag(%Q{li.generic_action input[@value="Custom Cancel"]})
            end
          end
  
        end
      end
    end
  
    describe 'when used on an existing record' do
      before do
        allow(@new_post).to receive(:persisted?).and_return(true)
      end
  
      describe 'when explicit label is provided' do
        it 'should render an input with the explicitly specified label' do
          concat(semantic_form_for(@new_post) do |builder|
            concat(builder.action(:submit, :as => :generic, :label => "Click!"))
            concat(builder.action(:reset, :as => :generic, :label => "Reset!"))
            concat(builder.action(:cancel, :as => :generic, :label => "Cancel!"))
          end)
          expect(output_buffer).to have_tag('li.generic_action input[@value="Click!"]')
          expect(output_buffer).to have_tag('li.generic_action input[@value="Reset!"]')
          expect(output_buffer).to have_tag('li.generic_action input[@value="Cancel!"]')
        end
      end
  
      describe 'when no explicit label is provided' do
        describe 'when no I18n-localized label is provided' do
          before do
            ::I18n.backend.store_translations :en, :formtastic => {
              :update => 'Save %{model}',
              :reset => 'Reset %{model}',
              :cancel => 'Cancel %{model}',
              :actions => {
                :message => {
                  :submit => 'Submit message',
                  :reset => 'Reset message',
                  :cancel => 'Cancel message'
                }
              }
            }
          end
  
          after do
            ::I18n.backend.reload!
          end
  
          it 'should render an input with default I18n-localized label (fallback)' do
            concat(semantic_form_for(@new_post) do |builder|
              concat(builder.action(:submit, :as => :generic))
              concat(builder.action(:reset, :as => :generic))
              concat(builder.action(:cancel, :as => :generic))
            end)
            expect(output_buffer).to have_tag('li.generic_action input[@value="Save Post"]')
            expect(output_buffer).to have_tag('li.generic_action input[@value="Reset Post"]')
            expect(output_buffer).to have_tag('li.generic_action input[@value="Cancel Post"]')
          end

          it 'should render an input with custom resource name localized label' do
            concat(semantic_form_for(:post, :as => :message, :url => 'http://example.com') do |builder|
              concat(builder.action(:submit, :as => :generic))
              concat(builder.action(:reset, :as => :generic))
              concat(builder.action(:cancel, :as => :generic))
            end)
            expect(output_buffer).to have_tag('li.generic_action input[@value="Submit message"]')
            expect(output_buffer).to have_tag('li.generic_action input[@value="Cancel message"]')
            expect(output_buffer).to have_tag('li.generic_action input[@value="Reset message"]')
          end
        end
  
        describe 'when I18n-localized label is provided' do
          before do
            ::I18n.backend.reload!
            ::I18n.backend.store_translations :en,
              :formtastic => {
                  :actions => {
                    :update => 'Custom Save',
                    :reset => 'Custom Reset',
                    :cancel => 'Custom Cancel'
                   }
                }
          end
  
          after do
            ::I18n.backend.reload!
          end
  
          it 'should render an input with localized label (I18n)' do
            with_config :i18n_lookups_by_default, true do
              ::I18n.backend.store_translations :en,
                :formtastic => {
                    :actions => {
                      :post => {
                        :update => 'Custom Save %{model}',
                        :reset => 'Custom Reset %{model}',
                        :cancel => 'Custom Cancel %{model}'
                       }
                     }
                  }
              concat(semantic_form_for(@new_post) do |builder|
                concat(builder.action(:submit, :as => :generic))
                concat(builder.action(:reset, :as => :generic))
                concat(builder.action(:cancel, :as => :generic))
              end)
              expect(output_buffer).to have_tag(%Q{li.generic_action input[@value="Custom Save Post"]})
              expect(output_buffer).to have_tag(%Q{li.generic_action input[@value="Custom Reset Post"]})
              expect(output_buffer).to have_tag(%Q{li.generic_action input[@value="Custom Cancel Post"]})
            end
          end
  
          it 'should render an input with anoptional localized label (I18n) - if first is not set' do
            with_config :i18n_lookups_by_default, true do
              concat(semantic_form_for(@new_post) do |builder|
                concat(builder.action(:submit, :as => :generic))
                concat(builder.action(:reset, :as => :generic))
                concat(builder.action(:cancel, :as => :generic))
              end)
              expect(output_buffer).to have_tag(%Q{li.generic_action input[@value="Custom Save"]})
              expect(output_buffer).to have_tag(%Q{li.generic_action input[@value="Custom Reset"]})
              expect(output_buffer).to have_tag(%Q{li.generic_action input[@value="Custom Cancel"]})
              ::I18n.backend.store_translations :en, :formtastic => {}
            end
          end
  
        end
      end
    end
  end

  describe 'when the model is two words' do

    before do
      output_buffer = ActiveSupport::SafeBuffer.new ''
      class ::UserPost
        extend ActiveModel::Naming if defined?(ActiveModel::Naming)
        include ActiveModel::Conversion if defined?(ActiveModel::Conversion)
    
        def id
        end
    
        def persisted?
        end
    
        # Rails does crappy human_name
        def self.human_name
          "User post"
        end
      end
      @new_user_post = ::UserPost.new
    
      allow(@new_user_post).to receive(:new_record?).and_return(true)
      concat(semantic_form_for(@new_user_post, :url => '') do |builder|
        concat(builder.action(:submit, :as => :generic))
        concat(builder.action(:reset, :as => :generic))
        concat(builder.action(:cancel, :as => :generic))
      end)
    end
    
    it "should render the string as the value of the button" do
      expect(output_buffer).to have_tag('li input[@value="Create User post"]')
      expect(output_buffer).to have_tag('li input[@value="Reset User post"]')
      expect(output_buffer).to have_tag('li input[@value="Cancel User post"]')
    end

  end

end
