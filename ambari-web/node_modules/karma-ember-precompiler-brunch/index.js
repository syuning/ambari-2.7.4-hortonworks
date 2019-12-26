var jsdom = require('jsdom');
var fs = require('fs');
var vm = require('vm');
var window = jsdom.jsdom().defaultView;

/*
  configs
    @param jqueryPath {String} - path to jquery.js
    @param handlebarsPath {String} - path to handlebars.js
    @param emberPath {String} - path to ember.js
*/

var createEmberBrunchPrecompilerPreprocessor = function(config, logger) {
  var log  = logger.create('preprocessor:ember-precompiler-brunch'),
      jquery, handlebars, ember;
  if (!config || !config.jqueryPath || !config.emberPath || !config.handlebarsPath) {
    log.error('You should specify all necessary configuration properties: `jqueryPath`, `handlebarsPath`, `emberPath`');
  } else {
    jquery = new vm.Script(fs.readFileSync(config.jqueryPath, 'utf8'));
    handlebars = new vm.Script(fs.readFileSync(config.handlebarsPath, 'utf8'));
    ember = new vm.Script(fs.readFileSync(config.emberPath, 'utf8'));
    jsdom.evalVMScript(window, jquery);
    jsdom.evalVMScript(window, handlebars);
    jsdom.evalVMScript(window, ember);
  }

  return function(content, file, done) {
    var processed = null;
    try {
      var compiled = window.Ember.Handlebars.precompile(content);
      log.debug("Precompiling %s", file.originalPath);
      processed = "Ember.TEMPLATES[module.id] = Ember.Handlebars.template(" + compiled + ");\nmodule.exports = module.id;";
    } catch (e) {
      log.error("%s\n at %s", e.message, file.originalPath);
    }

    done(processed);
  }
}

createEmberBrunchPrecompilerPreprocessor.$inject = ['config.emberPrecompilerBrunchPreprocessor', 'logger']

module.exports = {
  'preprocessor:ember-precompiler-brunch': ['factory', createEmberBrunchPrecompilerPreprocessor]
};
