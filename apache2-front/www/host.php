<html>
  <head>
    <link rel="icon" type="image/png" href="data:image/png;base64,iVBORw0KGgo=">
  </head>
  <body>
    <table>
      <tbody>
        <tr>
          <th> hostname </th>
          <td> <?php echo gethostname(); ?></td>
        </tr>
        <tr>
          <th> ip </th>
          <td> <?php echo gethostbyname(gethostname()); ?> </td>
        </tr>
      </tbody>
    </table>
  </body>
</html>
