(function() {
  'use strict';
  var CND, PATH, alert, badge, debug, echo, get_tree, help, info, rpr, urge, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'RESOLVE-NPM-DEPS';

  debug = CND.get_logger('debug', badge);

  alert = CND.get_logger('alert', badge);

  whisper = CND.get_logger('whisper', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  info = CND.get_logger('info', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  PATH = require('path');

  // FS                        = require 'fs'
  //...........................................................................................................
  // types                     = require './types'
  // { isa
  //   validate
  //   cast
  //   check
  //   declare
  //   declare_check
  //   is_sad
  //   type_of }               = types.export()
  get_tree = require('npm-logical-tree');

  //-----------------------------------------------------------------------------------------------------------
  this.get_package_dependencies = function(path) {
    /* Given a `path` to an npm  module that should contain a `package.json` and a `package-lock.json` file,
    return a report of transitive dependencies. The report will be an object with three fields:

    * **`packages`**—a list of pairs of package names and versions (`[ 'name', '1.1.0', ]`); these are in
      their installation order, i.e. each versioned package appears earlier than the packages that depend on
      it.

    * **`parents`**—an object whose keys are JSON representations os the values of `packages`, so like
      `'["opentype.js","1.3.3"]'`, and whose values are pairs of package names and versions as above.

    * **`duplicates`**—An object whose keys are unversioned package names and whose values are lists of
      versions in no particular order.

     */
    var d, duplicates, i, k, key, len, name, packages, parents, pkg, pkgLock, tree, value, version, versions;
    pkg = require(PATH.join(path, 'package.json'));
    pkgLock = require(PATH.join(path, 'package-lock.json'));
    tree = get_tree(pkg, pkgLock);
    ({packages, parents} = this._get_package_dependencies(tree));
//.........................................................................................................
// Assemble a string `parent@version, parent@version, ...` for each package:
    for (key in parents) {
      value = parents[key];
      value = [...value];
      value = (function() {
        var i, len, results;
        results = [];
        for (i = 0, len = value.length; i < len; i++) {
          k = value[i];
          results.push(JSON.parse(k));
        }
        return results;
      })();
      parents[key] = value;
    }
    //.........................................................................................................
    // Keep only first appearance of each versioned package in dependency-sorted list:
    packages = [...(new Set(packages))];
    packages = (function() {
      var i, len, results;
      results = [];
      for (i = 0, len = packages.length; i < len; i++) {
        d = packages[i];
        results.push(JSON.parse(d));
      }
      return results;
    })();
    //.........................................................................................................
    // Based on the packages list, find dependencies with more than a single version:
    duplicates = {};
    for (i = 0, len = packages.length; i < len; i++) {
      [name, version] = packages[i];
      (duplicates[name] != null ? duplicates[name] : duplicates[name] = new Set()).add(version);
    }
    for (name in duplicates) {
      versions = duplicates[name];
      if (versions.size < 2) {
        delete duplicates[name];
        continue;
      }
      duplicates[name] = [...versions];
    }
    //.........................................................................................................
    return {packages, parents, duplicates};
  };

  //-----------------------------------------------------------------------------------------------------------
  this._get_package_dependencies = function(tree, R = null, seen = null, level = 0) {
    var base, name, parent_key, ref, sub_key, sub_tree, target, x;
    if (seen == null) {
      seen = new WeakSet();
    }
    if (R == null) {
      R = {
        packages: [],
        parents: {}
      };
    }
    // dent        = '  '.repeat level ### verbose ###
    parent_key = JSON.stringify([tree.name, tree.version]);
    seen.add(tree);
    if (level > 0) {
      R.packages.unshift(parent_key);
    }
    ref = tree.dependencies.entries();
    // urge "#{dent}#{parent_key}" ### verbose ###
    for (x of ref) {
      [name, sub_tree] = x;
      sub_key = JSON.stringify([sub_tree.name, sub_tree.version]);
      target = (base = R.parents)[sub_key] != null ? base[sub_key] : base[sub_key] = new Set();
      target.add(parent_key);
      if (seen.has(sub_tree)) {
        R.packages.unshift(sub_key);
        // whisper "#{dent}#{sub_key} (circular)" ### verbose ###
        continue;
      }
      this._get_package_dependencies(sub_tree, R, seen, level + 1);
    }
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.get_intershop_addon_installation_order = function(path) {
    var dependencies, duplicates, name, packages, parents, version;
    dependencies = this.get_package_dependencies(path);
    ({packages, parents, duplicates} = dependencies);
    // info packages ### verbose ###
    // urge parents ### verbose ###
    // info duplicates ### verbose ###
    this._complain_about_duplicates(dependencies);
    return (function() {
      var i, len, results;
      results = [];
      for (i = 0, len = packages.length; i < len; i++) {
        [name, version] = packages[i];
        if (/^intershop-/.test(name)) {
          results.push([name, version]);
        }
      }
      return results;
    })();
  };

  //-----------------------------------------------------------------------------------------------------------
  this._complain_about_duplicates = function(dependencies) {
    var duplicate_names, duplicates, i, key, len, p, package_name, packages, parents, ref, required_by, v, version, versions;
    // Complain about duplicates (only one version of a given InterShop Addon can be installed as they all
    // write to the same DB):
    ({packages, parents, duplicates} = dependencies);
    duplicate_names = [];
    for (package_name in duplicates) {
      versions = duplicates[package_name];
      if (!/^intershop-/.test(package_name)) {
        continue;
      }
      warn(`multiple versions of package ${rpr(package_name)} detected:`);
      duplicate_names.push(package_name);
      for (i = 0, len = versions.length; i < len; i++) {
        version = versions[i];
        key = JSON.stringify([package_name, version]);
        required_by = (ref = parents[key]) != null ? ref : [["UNKNOWN", "UNKNOWN"]];
        required_by = (function() {
          var j, len1, results;
          results = [];
          for (j = 0, len1 = required_by.length; j < len1; j++) {
            [p, v] = required_by[j];
            results.push(`${p}@${v}`);
          }
          return results;
        })();
        required_by = required_by.join(', ');
        warn(`  version ${version} required_by by ${required_by}`);
      }
    }
    if (duplicate_names.length > 0) {
      throw new Error(`duplicate versions for packages ${duplicate_names.join(', ')} detected; see details above`);
    }
    return null;
  };

}).call(this);

//# sourceMappingURL=resolve-intershop-addon-installation-order.js.map