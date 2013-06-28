$(function(){
  
  _.templateSettings = {
      interpolate: /\{\{\=(.+?)\}\}/g,
      evaluate: /\{\{(.+?)\}\}/g
  };

  var Org = Backbone.Model.extend({
    urlRoot : '/organizations'
  });

  var OrgCollection = Backbone.Collection.extend({
    model: Org,
    url: '/organizations'
  })

  var OrgView = Backbone.View.extend({
    tagName: "option",
    template: _.template($('#org-template').html()),
    render: function() {
      this.$el.html(this.template(this.model.toJSON()));  
      return this;
    }
  });

  var SpaceView = Backbone.View.extend({
    tagName: "li",
    template: _.template($('#space-template').html()),
    className: "space-tab",
    id: function() {
      return "space-" + this.model.guid;
    },
    render: function() {
      this.$el.html(this.template(this.model));  
      return this;
    }
  });

  var AppsView =  Backbone.View.extend({
    tagName: "table",
    template: _.template($("#apps-template").html()),
    className: "apps-table table table-condensed table-striped",
    id: function() {
      return "space-" + this.model.guid + "-apps";
    },
    render: function() {
      this.$el.html(this.template(this.model));  
      return this;
    }
  });

  var AccountView = Backbone.View.extend({
    el: $('#account-tab-view'),
    initialize: function(accountId) {
      this.orgs = new OrgCollection();
      this.selectedOrg = null;
      this.selectedSpace = null;
      this.listenTo(this.orgs, 'add', this.addOne);
      this.listenTo(this.orgs, 'sync', this.redraw);
      this.listenTo(this.orgs, 'all', this.render);
    },
    events: {
      "change #org-list": "orgSelected",
      "click .space-tab": function (o) { 
        var guid = o.currentTarget.id.replace("space-", ""); 
        this.switchSpace(guid); 
      }
    },
    orgSelected: function(e) {
      value = e.currentTarget.value;
      this.switchOrg(value);
    },
    switchOrg: function(guid) {
      console.log("Selecting org - " + guid);
      var org = _.select(accountView.orgs.models, function(org) { return org.attributes.guid == guid })[0].attributes;
      this.selectedOrg = org;

      this.$("#space-list > li").hide();

      var spacesToView = _.collect(org.spaces, function(s) { return "#space-list > li#space-" + s.guid }).join(", ");
      this.$(spacesToView).show();

      this.switchSpace(org.spaces[0].guid);
    },
    switchSpace: function(guid) {
      console.log("Selecting space - " + guid);
      var space = _.select(this.selectedOrg.spaces, function(space) { return space.guid == guid})[0];
      this.selectedSpace = space;

      // show correct app table
      this.$(".apps-table").hide();
      this.$("#app-tables > table#space-" + guid + "-apps").show();

      // select correct tab
      this.$(".space-tab").removeClass('active');
      this.$("#space-" + guid).addClass('active');
    },
    fetchAccounts: function(accountId) {
      accountView = this;
      this.orgs.fetch({
        data: {
          account_id: accountId
        },
        success: function(){
          accountView.switchOrg(accountView.orgs.first().attributes.guid);

          //remove any empty spaces or ones without summary
          _.each(accountView.orgs.models, function(org) {
            org.attributes.spaces = _.reject(org.attributes.spaces, function(space) { return ((space.app_count == 0) || (typeof(space.summary) != "object")); });
          });
        }
      }); 
    },
    addOne: function(org) {
      var view = new OrgView({model: org});
      var orgItem = view.render().el;
      $(orgItem).attr('value', org.attributes.guid);
      this.$("#org-list").append(orgItem);

      _.each(org.attributes.spaces, function (space) {

        if ((space.app_count > 0) && (typeof(space.summary) == "object")) {
          var spaceView = new SpaceView({model: space});
          var spaceItem = spaceView.render().el;
          this.$("#space-list").append(spaceItem);

          var appsView = new AppsView({model: space});
          var appsItem = appsView.render().el;
          this.$("#app-tables").append(appsItem);
        }

      });
    }
  })

  window.AccountView = AccountView;
});