// Generated by CoffeeScript 2.5.1
(function() {
  'use strict';
  var CND, alert, badge, crypto, debug, help, info, password, rpr, text, text_c, text_r, urge, warn, whisper;

  /* https://ponyfoo.com/articles/understanding-javascript-async-await */
  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'YAU/DEMO-2';

  debug = CND.get_logger('debug', badge);

  alert = CND.get_logger('alert', badge);

  whisper = CND.get_logger('whisper', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  info = CND.get_logger('info', badge);

  crypto = require('crypto');

  this._demo = function() {
    var cipher, i, len, ref, results;
    ref = crypto.getCiphers();
    results = [];
    for (i = 0, len = ref.length; i < len; i++) {
      cipher = ref[i];
      if ((cipher.match(/aes/)) == null) {
        // debug cipher
        continue;
      }
      if (cipher.endsWith('wrap')) {
        // continue unless ( cipher.match /aes-128|rc4|rc2/ )?
        // continue unless ( cipher.match /cb|rc4|rc2/ )?
        continue;
      }
      if (cipher.endsWith('xts')) {
        continue;
      }
      if (cipher === 'aes-128-ccm' || cipher === 'aes-128-ctr' || cipher === 'aes-128-gcm' || cipher === 'aes-192-ccm' || cipher === 'aes-192-ctr' || cipher === 'aes-192-gcm' || cipher === 'aes-256-ccm' || cipher === 'aes-256-ctr' || cipher === 'aes-256-gcm' || cipher === 'id-aes128-CCM' || cipher === 'id-aes128-GCM' || cipher === 'id-aes192-CCM' || cipher === 'id-aes192-GCM' || cipher === 'id-aes256-CCM' || cipher === 'id-aes256-GCM') {
        continue;
      }
      help(this.encrypt('secret', 'x', cipher), `(${cipher})`);
      urge(this.encrypt('secret', 'xx', cipher), `(${cipher})`);
      urge(this.encrypt('secret', 'xxxx', cipher), `(${cipher})`);
      results.push(urge(this.encrypt('secret', 'xxxxxx', cipher), `(${cipher})`));
    }
    return results;
  };

  // help encrypted, "(#{cipher})"

  // decrypter   = crypto.createDecipher 'aes192', 'a password'
  // encrypted   = 'ca981be48e90867604588e75d04feabb63cc007a8f8ad89b10616ed84d815504';
  // decrypted   = decrypter.update encrypted, 'hex', 'utf8'
  // decrypted  += decrypter.final 'utf8'
  // info decrypted

  //-----------------------------------------------------------------------------------------------------------
  this._default_cipher = 'aes128';

  this._salt_length = 5;

  //-----------------------------------------------------------------------------------------------------------
  this._salt = function() {
    /* TAINT not a very good salt */
    var R;
    R = ('x'.repeat(this._salt_length)) + Math.random();
    return R.slice(R.length - this._salt_length);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.encrypt = function(password, text, cipher = null) {
    var R, encrypter, salt;
    if (cipher == null) {
      cipher = this._default_cipher;
    }
    salt = this._salt();
    encrypter = crypto.createCipher(cipher, password);
    R = encrypter.update(salt, 'utf8', 'hex');
    R = encrypter.update(text, 'utf8', 'hex');
    R += encrypter.final('hex');
    // encrypter1  = crypto.createCipher cipher, password
    // R1          = encrypter1.update salt, 'utf8', 'base64'
    // R1          = encrypter1.update text, 'utf8', 'base64'
    // R1         += encrypter1.final 'base64'
    // debug R1
    R = `${cipher}:${R}`;
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.decrypt = function(password, text) {
    var R, cipher, decrypter, error;
    [cipher, text] = text.split(':');
    try {
      decrypter = crypto.createDecipher(cipher, password);
      R = decrypter.update(text, 'hex', 'utf8');
      R += decrypter.final('utf8');
    } catch (error1) {
      error = error1;
      throw new Error(`unable to decrypt (${error.message})`);
    }
    R = R.slice(this._salt_length);
    return R;
  };

  text = "abcdef";

  password = 'secret';

  help(text);

  help(text_c = this.encrypt(password, text));

  help(text_r = this.decrypt('secret', text_c));

  help(CND.truth(text_r === text));

  // @_demo()
// debug @_salt()
// debug @_salt()
// debug @_salt()

}).call(this);

//# sourceMappingURL=encrypt.js.map
