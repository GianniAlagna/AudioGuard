<?php
require 'config.php';
require 'lib/db.php';
require 'lib/auth.php';

$error = '';
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (auth_login($_POST['user'], $_POST['pass'])) {
        header('Location: dashboard.php');
        exit;
    }
    $error = 'Login fehlgeschlagen.';
}
$title = 'Login';
include 'templates/header.tpl.php';
?>
<div id="login">
  <h2>AudioGuard</h2>
  <?php if ($error): ?><p class="error"><?php echo h($error); ?></p><?php endif; ?>
  <form method="post" action="index.php">
    <label>Kürzel <input type="text" name="user" size="10" /></label>
    <label>Passwort <input type="password" name="pass" /></label>
    <input type="submit" value="Anmelden" />
  </form>
</div>
<?php include 'templates/footer.tpl.php'; ?>
