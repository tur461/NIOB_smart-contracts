const { promisify } = require('util');
const { resolve } = require('path');
const fs = require('fs');
const readdir = promisify(fs.readdir);
const stat = promisify(fs.stat);

const CONTRACTS_PATH = './artifacts/contracts';
const ABI_PATH = './all_abis';
const FILTER = {
  DBG_FILE: '.dbg.',
  IFACE_FILE: 'interfaces',
};

const PATH_SEP = {
  WIN: '//',
  LINUX: '/',
};

const path_sep = PATH_SEP.LINUX;

// add 'I' prefixed contract names (i mean not interfaces!)
const whitelisted = [
  'IDO',
];

let no_xtensions = [];

function not_whitelisted(n) {
  return whitelisted.indexOf(n) === -1;
}

function push_f(fpath) {
    let splits = fpath.split(path_sep);
    let d = splits[splits.length-1].split('.')[0];
    if(d[0] === 'I' && not_whitelisted(d))
      no_xtensions.push(d);
}

function not_an_iface(f) {
  f = f.split('.')[0];
  let is_I = no_xtensions.indexOf(f) === -1;  
  // console.log(f, 'is an interface', !is_I);
  return is_I;
}

function is_valid_file(f) {
  return f.indexOf(FILTER.DBG_FILE) === -1 && f.indexOf(FILTER.IFACE_FILE) === -1;
}

async function get_files(dir) {
  const subdirs = await readdir(dir);
  const files = await Promise.all(subdirs.map(async (subdir) => {
    const res = resolve(dir, subdir);
    return (await stat(res)).isDirectory() ? get_files(res) : res;
  }));
  return files.filter(f => is_valid_file(f)).reduce((a, f) => a.concat(f), []);
}
function read_files(files, onFileContent, onError) {
  files.forEach(f => push_f(f));
  //console.log('no xtensions:', no_xtensions);
  files.forEach(fname => {
    fs.readFile(fname, 'utf-8', (err, content) => {
      if (err) {
        onError(err);
        return;
      }
      onFileContent(fname, JSON.parse(content));
    });
  });
}

function get_fname(fname) {
    let splits = fname.split(path_sep);
    return splits[splits.length-1];
}

function create_abi_files() {
    get_files(CONTRACTS_PATH)
    .then(files => {
        if (!fs.existsSync(ABI_PATH)){
            fs.mkdirSync(ABI_PATH);
        }
        read_files(files, (fname, json) => {
            let abi = JSON.stringify(json.abi);
            fname = get_fname(fname);
            if(abi.length && not_an_iface(fname))
                fs.writeFileSync(ABI_PATH + path_sep + fname, abi);
        }, _ => {})
    })
    .catch(err => console.log('error:', err));
}

create_abi_files();
