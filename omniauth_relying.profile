<?php

/**
 * Implements hook_install()
 */
function omniauth_relying_install() {
  module_enable(array('omniauth_relying_core'));

  // Greetings
  watchdog('Omniauth',
    t('Welcome to Omniauth OpenID Single Sign-On brought to you by !ef_link.',
      array(
        '!ef_link' => l('erdfisch', 'http://erdfisch.de'),
      )
    )
  );
}

function omniauth_relying_install_tasks() {
  $task['omniauth_relying'] = array(
    'display_name' => st('OpenID Provider configuration'),
    'display' => TRUE,
    'type' => 'form',
    'run' => INSTALL_TASK_RUN_IF_REACHED,
    'function' => 'omniauth_relying_configuration',
  );

  return $task;
}

function omniauth_relying_configuration() {
  $form['openid_sso_relying_provider'] = array(
    '#type' => 'fieldset',
    '#title' => t('OpenID Provider'),
    '#description' => t('A designated OpenID Provider with Single Sign-On support. This should be another Drupal site with !openid_provider module and !openid_sso_provider module installed and configured.', array(
      '!openid_provider' => l(t('OpenID Provider'), 'http://drupal.org/project/openid_provider'),
      '!openid_sso_provider' => l(t('OpenID Single Sign On Provider'), 'http://drupal.org/project/openid_sso_provider'),
     )),
    '#tree' => TRUE,
  );
  $form['openid_sso_relying_provider']['name'] = array(
    '#type' => 'textfield',
    '#title' => t('Name'),
    '#description' => t('The site name of the provider.'),
  );
  $form['openid_sso_relying_provider']['url'] = array(
    '#type' => 'textfield',
    '#title' => t('URL'),
    '#description' => t('The full URL of the provider, must contain a trailing slash.'),
  );
  // Add an additional validation and submit handler to process the form
  $form['#validate'][] = 'omniauth_install_configure_form_validate';
  $form['#submit'][] = 'omniauth_install_configure_form_submit';
  $form['submit'] = array('#type' => 'submit', '#value' => t('Submit'));
  return $form;
}


/**
 * Alter the install profile configuration form and provide timezone location options.
 */
function system_form_install_configure_form_alter(&$form, $form_state) {
  $form['site_information']['site_name']['#default_value'] = $_SERVER['SERVER_NAME'];
  $form['site_information']['site_mail']['#default_value'] = 'admin@'. $_SERVER['HTTP_HOST'];
  $form['admin_account']['account']['name']['#default_value'] = 'admin';
  $form['admin_account']['account']['mail']['#default_value'] = 'admin@'. $_SERVER['HTTP_HOST'];
}

/**
 * Validation handler for the installation configure form
 */
function omniauth_install_configure_form_validate(&$form, &$form_state) {
  if (!empty($form_state['values']['openid_sso_relying_provider']['url']) && 
    !preg_match('/^http:\/\/.*\/$/', $form_state['values']['openid_sso_relying_provider']['url'])) {
    form_set_error('openid_sso_relying_provider][url', t('Please enter a valid provider OpenID Single Sign On url.'));
  }
  if (!empty($form_state['values']['openid_sso_relying_provider']['url']) && empty($form_state['values']['openid_sso_relying_provider']['name'])) {
    form_set_error('openid_sso_relying_provider][name', t('Please enter a name for the OpenID Single Sign On provider.'));
  }
}

/**
 * Submit handler for the installation configure form
 */
function omniauth_install_configure_form_submit(&$form, &$form_state) {
  if (!empty($form_state['values']['openid_sso_relying_provider']['url'])) {
    variable_set('openid_sso_relying_provider', $form_state['values']['openid_sso_relying_provider']);
  }

  // Advice the user about the direct login.
  global $base_url, $base_path;
  drupal_set_message(t('You have set up an OpenID Single Sign On reyling party site. All user logins are redirected to the provider. To log in with your admin account to this site you have to use the direct login: !site-login', array('!site-login' => l('login/direct', $base_url . $base_path . 'login/direct'))), 'warning');
}
