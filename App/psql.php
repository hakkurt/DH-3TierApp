<?php
    $myPDO = new PDO('pgsql:host=db-ip;dbname=dh', 'postgres', 'VMware1!');

    $results = $myPDO->query("SELECT * FROM actor order by actor_id LIMIT 20 ");
?>

  <!DOCTYPE html>
<html>
    <head>
        <title>PostgreSQL PHP Querying Data Demo</title>
        <link rel="stylesheet" href="https://cdn.rawgit.com/twbs/bootstrap/v4-dev/dist/css/bootstrap.css">
    </head>
    <body>
        <div class="container">
            <h1>Actor List</h1>
            <table class="table table-bordered">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>First Name</th>
                        <th>Last Name</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($results as $result) : ?>
                        <tr>
                            <td><?php echo htmlspecialchars($result['actor_id']) ?></td>
                            <td><?php echo htmlspecialchars($result['first_name']); ?></td>
                            <td><?php echo htmlspecialchars($result['last_name']); ?></td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </body>
</html>
	

