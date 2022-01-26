var OPTICS = require('./modules/density-clustering').OPTICS;
var mysql = require('./modules/mysql');

var connection = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'rp'
});

var ItemsDB = [];
var CentersDB = [];
var RemoveDB = [];
var radius = [];

function updateclusters() {
  connection.query(`SELECT px, py, pz, NetID, model, roll, pitch, yaw FROM props;`,
    function (error, results, fields) {
      var centers = [];
      var dataset = [];
      if (error)
        throw error;
      results.forEach(function (obj) {
        dataset.push(Object.values(obj).slice(0, 3));
      });

      var optics = new OPTICS();
      var clusters = optics.run(dataset, 50, 2);
      ItemsDB = [];
      for (var i = 0; i < clusters.length; i++) {
        centers.push([0, 0, 0]);
        var items = [];
        clusters[i].forEach(function (index) {
          centers[i][0] += parseFloat(dataset[index][0]);
          centers[i][1] += parseFloat(dataset[index][1]);
          centers[i][2] += parseFloat(dataset[index][2]);
          items.push(Object.values(results[index]))
        });
        centers[i][0] /= clusters[i].length;
        centers[i][1] /= clusters[i].length;
        centers[i][2] /= clusters[i].length;

        ItemsDB.push(items);
        var r = [];
        clusters[i].forEach(function (index) {
          var rad = Math.hypot(parseFloat(dataset[index][0]) - centers[i][0], parseFloat(dataset[index][1]) - centers[i][1],
            parseFloat(dataset[index][2]) - centers[i][2]);
          r.push(rad)
        });
        radius.push(Math.max(...r));
      }
      emitNet('UpdateClusters', -1, centers, radius);
      CentersDB = [];
      CentersDB = [...centers];
    });
}

onNet('newprop', (NetID, model, px, py, pz, roll, pitch, yaw) => {
  connection.query(`INSERT INTO props VALUES (${NetID}, ${model}, ${px}, ${py}, ${pz}, ${roll}, ${pitch}, ${yaw});`,
    function (error, results, fields) {
      if (error)
        throw error;
    });
  updateclusters();
})

onNet('InitClusters', (serverid) => {
  emitNet('UpdateClusters', serverid, CentersDB, radius);
});

onNet('RequestObjects', (serverid) => {
  emitNet('CreateObjects', serverid, ItemsDB);
});

onNet('RequestRemove', (serverid) => {
  emitNet('RemoveObjects', serverid, RemoveDB);
});

onNet('RemoveProp', (NetID) => {
  connection.query(`DELETE FROM props WHERE NetID=${NetID};`,
    function (error, results, fields) {
      if (error) throw error;
    });
  RemoveDB.push(NetID);
  updateclusters();
});