<?php


/**
 * Perform any final installation tasks for this profile.
 *
 * The installer goes through the profile-select -> locale-select
 * -> requirements -> database -> profile-install-batch
 * -> locale-initial-batch -> configure -> locale-remaining-batch
 * -> finished -> done tasks, in this order, if you don't implement
 * this function in your profile.
 *
 * If this function is implemented, you can have any number of
 * custom tasks to perform after 'configure', implementing a state
 * machine here to walk the user through those tasks. First time,
 * this function gets called with $task set to 'profile', and you
 * can advance to further tasks by setting $task to your tasks'
 * identifiers, used as array keys in the hook_profile_task_list()
 * above. You must avoid the reserved tasks listed in
 * install_reserved_tasks(). If you implement your custom tasks,
 * this function will get called in every HTTP request (for form
 * processing, printing your information screens and so on) until
 * you advance to the 'profile-finished' task, with which you
 * hand control back to the installer. Each custom page you
 * return needs to provide a way to continue, such as a form
 * submission or a link. You should also set custom page titles.
 *
 * You should define the list of custom tasks you implement by
 * returning an array of them in hook_profile_task_list(), as these
 * show up in the list of tasks on the installer user interface.
 *
 * Remember that the user will be able to reload the pages multiple
 * times, so you might want to use variable_set() and variable_get()
 * to remember your data and control further processing, if $task
 * is insufficient. Should a profile want to display a form here,
 * it can; the form should set '#redirect' to FALSE, and rely on
 * an action in the submit handler, such as variable_set(), to
 * detect submission and proceed to further tasks. See the configuration
 * form handling code in install_tasks() for an example.
 *
 * Important: Any temporary variables should be removed using
 * variable_del() before advancing to the 'profile-finished' phase.
 *
 * @param $task
 *   The current $task of the install system. When hook_profile_tasks()
 *   is first called, this is 'profile'.
 * @param $url
 *   Complete URL to be used for a link or form action on a custom page,
 *   if providing any, to allow the user to proceed with the installation.
 *
 * @return
 *   An optional HTML string to display to the user. Only used if you
 *   modify the $task, otherwise discarded.
 */
function omniauth_relying_profile_tasks(&$task, $url) {

  // Greetings
  watchdog('Omniauth',
    t('Welcome to Omniauth OpenID-Simple-Sign-On brought to you by !ef_link.',
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
    '#description' => t('A designated OpenID Provider with Simple Sign-On support. This should be another Drupal site with !openid_provider module and !openid_sso_provider module installed and configured.', array(
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
