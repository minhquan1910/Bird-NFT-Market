import {ethers} from 'ethers'
import {useEffect, useState} from 'react'
import Web3Modal from 'web3modal'
import {create, create as ipfsHttpClient} from 'ipfs-http-client'
import {nftaddress, nftmarketaddress} from '../config'
import NFT from '../artifacts/contracts/NFT.sol/NFT.json'
import KBMarket from '../artifacts/contracts/KBMarket.sol/KBMarket.json'
import { useRouter } from 'next/router'
import { NFTStorage, File } from 'nft.storage'
import { Web3Storage } from 'web3.storage'
import mime from 'mime'
import path from 'path'
import * as fs from 'fs'


// set ipfs for host nft data
// file storage
const project_id = '2FW2eSqAz7uJjDXUv2IUp1dcsBr'
const project_secret = '609e165e042b33c58a4bcd4944bf0684'
const auth = 'Basic ' + Buffer.from(project_id + ':' + project_secret).toString('base64');
const client = create({
    host: 'ipfs.infura.io',
    port: 5001,
    protocol: 'https',
    headers: {
        authorization: auth,
    },
});

export default function MintItem(){
    const [fileUrl, setFileUrl] = useState(null)
    const [formInput, updateFormInput] = useState({price:'',name:'',description:''})
    const router = useRouter()

    //NFT image - IPFS image
    async function onChange(e){
        const file = e.target.files[0]
        try{
            const added = await client.add(
                file, {
                    progress:(prog) => console.log(`received: ${prog}`)
                }
            )
            const url = `https://nuyq.infura-ipfs.io/ipfs/${added.path}`
            setFileUrl(url)
            console.log(url)

            
        }catch(error){
            console.log('Error uploading file', error)
        }
    }
    
    async function createMarket(){
        const {name, description, price} = formInput
        if(!name || !description || !price || !fileUrl) return

        const data = JSON.stringify({
            name, description, image: fileUrl
        })

        try{
            const added = await client.add(data)
            const url = `https://nuyq.infura-ipfs.io/ipfs/${added.path}`
            createSale(url)
        }catch(error){
            console.log('Error uploading file', error)
        }
    }

    async function createSale(url){
        const web3Modal = new Web3Modal()
        const connection = await web3Modal.connect()
        const provider = new ethers.providers.Web3Provider(connection)
        const signer = provider.getSigner()
        
        //Create a token
        let contract = new ethers.Contract(nftaddress, NFT.abi, signer)
        let transaction = await contract.mintToken(url)
        let tx = await transaction.wait()
        console.log("Tx: ",tx)
        let event = tx.events[0]
        console.log("Event: ", event)
        let value = event.args[2]
        let tokenId = value.toNumber()
        const price = ethers.utils.parseUnits(formInput.price, 'ether')

        //List the item for sale
        contract = new ethers.Contract(nftmarketaddress, KBMarket.abi, signer)
        let listingPrice = await contract.getListingPrice()
        listingPrice = listingPrice.toString()

        transaction = await contract.makeMarketItem(nftaddress, tokenId, price, {value: listingPrice})
        await transaction.wait()

        router.push('./')
    }

    return (
        <div className='flex justify-center'>
            <div className='w-1/2 flex flex-col pb-12'>
                <input
                placeholder='Asset Name'
                className='mt-8 border rounded p-4'
                onChange={e => updateFormInput({...formInput, name:e.target.value})}
                />
                <textarea
                placeholder='Asset Description'
                className='mt-2 border rounded p-4'
                onChange={e => updateFormInput({...formInput, description:e.target.value})}
                />
                <input
                placeholder='Asset Price'
                className='mt-2 border rounded p-4'
                onChange={e => updateFormInput({...formInput, price:e.target.value})}
                />
                <input
                type='file'
                name='Asset'
                className='mt-4'
                onChange={onChange}
                /> {
                    fileUrl && (
                        <img className='rounded mt-4' width='350px' src={fileUrl}/>
                    )
                }
                <button onClick={createMarket}
                className='font-bold mt-4 bg-purple-500 text-white rounded p-4 shadow-lg'
                >
                    Mint NFT
                </button>
            </div>
        </div>
    )

}

async function fileFromPath(filePath) {
    const content = await fs.promises.readFile(filePath)
    const type = mime.getType(filePath)
    return new File([content], path.basename(filePath), { type })
}
