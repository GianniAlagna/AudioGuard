<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de" lang="de">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>AudioGuard - <?php echo h($title); ?></title>
  <link rel="stylesheet" type="text/css" href="css/style.css" />
  <link rel="stylesheet" type="text/css" href="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.16/themes/smoothness/jquery-ui.css" />
  <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.6.2/jquery.min.js"></script>
  <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.16/jquery-ui.min.js"></script>
  <script type="text/javascript" src="js/app.js"></script>
</head>
<body>
<div id="wrap">
  <div id="head">
    <h1>Audio<b>Guard</b> <small>QT Records</small></h1>
    <?php if (!empty($_SESSION['ag_user'])): ?>
    <ul id="nav">
      <li><a href="dashboard.php">Dashboard</a></li>
      <li><a href="hits.php">Treffer</a></li>
      <li><a href="catalogue.php">Katalog</a></li><!-- TODO: catalogue.php not committed -->
      <li><a href="queue.php">Takedown Queue</a></li><!-- TODO -->
      <li class="right"><?php echo h($_SESSION['ag_user']); ?> | <a href="logout.php">Logout</a></li>
    </ul>
    <?php endif; ?>
  </div>
  <div id="content">
