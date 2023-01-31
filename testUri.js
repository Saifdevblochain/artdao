require("dotenv").config()
const { ethers, Contract } = require("ethers");
const abi = require("./abi.json")


const rpcUrl = process.env.URL; 
const deployedAddress = process.env.deployedAddress; //
const privatekey = process.env.PRIVATE_KEY; 

 
let provider = ethers.getDefaultProvider(rpcUrl); 

const wallet = new ethers.Wallet(privatekey, provider);
const contract = new ethers.Contract(deployedAddress, abi, provider);
let contractWithSigner = contract.connect(wallet);

(async()=>{
   
const fs = require("fs");
const csv = require("csv-parser");
let arr= []

fs.createReadStream("uri.CSV")
.pipe(csv())
.on("data", data => {
    let tempData = JSON.parse(JSON.stringify({...data}))
    arr.push(Object.values(tempData)[0])
}).on('end', async()=> {
  console.log('end::::', arr)
 
  for (let i=0; i< arr.length; i++) {
    await contractWithSigner.addNfts(arr[i]);
    console.log(arr[i])
  }
    
 
})



})()




