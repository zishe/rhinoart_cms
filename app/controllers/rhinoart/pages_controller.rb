# frozen_string_literal: true

require_dependency 'rhinoart/application_controller'

module Rhinoart
  class PagesController < BaseController
    before_action { authorize!(:manage, :content) }
    before_action :set_rhinoart_page, only: %i[edit update destroy]
    before_action :set_tree_ids, only: %i[index children edit]

    def index
      store_location
      if params[:parent].present?
        @pages = Page.paginate(page: params[:page]).where('parent_id = ? AND active = ?', params[:parent], true).order(:position, :name) # if parent.ptype == 'page'
      else
        @pages = Page.paginate(page: params[:page]).where('parent_id IS NULL AND active = ?', true).order(:position, :name)
      end

      respond_to do |format|
        format.html {}
        format.js {}
      end
    end

    def children
      store_location

      @parent = Page.find(params[:id])
      if Rails.configuration.order_in_list.present? && Rails.configuration.order_in_list.to_s == 'by_date'
        @pages = Page.unscoped.where('parent_id = ?', params[:id]).order('publish_date DESC, position asc')
      else
        @pages = Page.unscoped.where('parent_id = ?', params[:id]).order('position asc')
      end
      @level = params[:level]

      respond_to do |format|
        format.html {}
        format.js {}
      end
    end

    def new
      @page = Page.new

      if params[:id].present?
        @page.parent_id = params[:id]
        @page.ptype     = Page.find(@page.parent_id).ptype
      end

      if !@page.ptype.present?
        content_fields(@page)
        content_tabs(@page)
      else
        case @page.ptype
        when Page::TUPES[:article].to_s.downcase
          additional = [
            { name: 'image', ftype: 'file', position: 5 }
          ]
          content_fields(@page, 'default', additional)
          content_tabs(@page, %w[preview main_content])
        when Page::TUPES[:blog].to_s.downcase
          fields = [
            { name: 'title', ftype: 'title', position: 1 },
            { name: 'h1', ftype: 'title', position: 2 },
            { name: 'description', ftype: 'meta', position: 3 },
            { name: 'keywords', ftype: 'meta', position: 4 },
            { name: 'comment', ftype: 'boolean', position: 5, value: 1 }
          ]
          content_fields(@page, fields)
          content_tabs(@page, %w[short full])
        when Page::TUPES[:testimonial].to_s.downcase
          fields = [
            { name: 'title', ftype: 'title', position: 1 },
            { name: 'h1', ftype: 'title', position: 2 },
            { name: 'author', ftype: 'textarea', position: 3 },
            { name: 'image', ftype: 'file', position: 4 }
          ]
          content_fields(@page, fields)
          content_tabs(@page, %w[preview main_content])
        else
          content_fields(@page)
          content_tabs(@page)
        end
      end
    end

    def create
      @page = Page.new

      if @page.update_attributes(admin_pages_params)
        @page.move_to_top if @page.ptype == 'article'
        flash[:info] = t('_PAGE_SUCCESSFULLY_CREATED')
        if params[:continue].present?
          # redirect_to structure_path([@page, :edit])
          redirect_to :back
        else
          redirect_back_or pages_path
        end
      else
        render action: 'new'
      end
    end

    def edit; end

    def update
      if @page.update(admin_pages_params)
        update_page_content(@page, params[:page])

        flash.now[:info] = t('_PAGE_SUCCESSFULLY_UPDATED')
        if params[:continue].present?
          redirect_to :back
        else
          redirect_back_or pages_path
        end
      else
        render action: 'edit'
      end
    end

    def tree
      store_location
    end

    def destroy
      page_name = @page.name
      @page.destroy

      flash[:info] = t('_PAGE_SUCCESSFULLY_DELITED', name: page_name)
      redirect_back_or pages_path
    end

    def showhide
      page = Page.find(params[:id])
      page.update_attributes(active: !page.active?)

      redirect_back_or pages_path
    end

    def sort
      params[:page].each_with_index do |id, index|
        Page.update_all(['position=?', index + 1], ['id=?', id])
      end
      render nothing: true
    end

    def up
      @page = Page.find(params[:page_id])
      @page.move_higher
      redirect_to children_page_path(@page.parent)
    end

    def down
      @page = Page.find(params[:page_id])
      @page.move_lower
      redirect_to children_page_path(@page.parent)
    end

    def field_page_add
      @count_page = params[:count_page]

      @field_name = params[:field_name]
      @field_type = params[:field_type]

      field_new = [{ name: @field_name, ftype: @field_type, position: @count_page }]

      @page.page_field.build(field_new)

      @field = @page.page_field.last

      # debugger

      respond_to do |format|
        format.js
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_rhinoart_page
      @page = Page.find(params[:id])
    rescue
      render template: 'rhinoart/shared/error404', status: :not_found
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def admin_pages_params
      # params.require(:page).permit!
      params[:page].permit! # TODO
    end

    def set_tree_ids
      @tree_ids = cookies[:tree_ids].split(',').map(&:to_i) if cookies[:tree_ids].present?
    end

    def content_tabs(page, names = %w[main_content])
      names.each_with_index do |name, i|
        page.page_content.build(name: name, position: i + 1) if page.page_content.where("name = '#{name}'").empty?
      end
    end

    def content_fields(page, fields = 'default', additional = nil)
      if fields == 'default'
        fields = [
          { name: 'title', ftype: 'title', position: 1 },
          { name: 'h1', ftype: 'title', position: 2 },
          { name: 'description', ftype: 'meta', position: 3 },
          { name: 'keywords', ftype: 'meta', position: 4 }
        ]
      end

      fields.push(additional[0]) if additional

      fields.each do |field|
        field.assert_valid_keys(:name, :ftype, :position, :value) # валидация
        page.page_field.build(field)
      end
    end

    def update_page_field(page, params)
      originalFields = []
      page.page_field.each { |f| originalFields << f }

      # filter originalFields to contain params no longer present
      if params[:page_field_attributes].present?
        params[:page_field_attributes].each do |_fk, fv|
          originalFields.each do |of|
            originalFields.delete(of) if of.name.to_s.casecmp(fv[:name].to_s.downcase).zero?
          end
        end
      end

      originalFields.each(&:destroy)
    end

    def update_page_content(page, params)
      originalTabs = []
      page.page_content.each { |f| originalTabs << f }

      # filter originalTabs to contain params no longer present
      if params[:page_content_attributes].present?
        params[:page_content_attributes].each do |_fk, fv|
          originalTabs.each do |of|
            originalTabs.delete(of) if of.name.to_s.casecmp(fv[:name].to_s.downcase).zero?
          end
        end
      end

      # remove the relationship between the param and the Content
      originalTabs.each(&:destroy)
    end
  end
end
