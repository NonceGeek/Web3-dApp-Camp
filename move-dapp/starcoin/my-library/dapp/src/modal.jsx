import React from "react";
import { useEffect } from "react";
import { useState } from "react";
import classnames from "classnames";
import { createRoot } from "react-dom/client";
import { useCallback } from "react";
import { arrayify, hexlify } from "@ethersproject/bytes";
import { utils, bcs } from "@starcoin/starcoin";
import encoding from '@starcoin/starcoin';
import { starcoinProvider } from "./app";
import { executeFunction,executeFunction2 } from "./txs/counter.tx";
import { LIBRARY_ADDRESS, INIT_LIBRARY_FUNC_NAME, S_ADD_BOOK_FUNC_NAME } from "./txs/config";

export const makeModal = (props) => {
  const { children } = props;
  const escapeNode = document.createElement("div");
  const root = createRoot(escapeNode);
  document.body.appendChild(escapeNode);
  const onClose = () => {
    root.unmount();
    if (document.body.contains(escapeNode)) {
      document.body.removeChild(escapeNode);
    }
  };
  const Child = children({ onClose });
  root.render(<>{Child}</>);
};

const useFadeIn = () => {
  const [isShow, setShow] = useState(false);

  useEffect(() => {
    setTimeout(() => {
      setShow(true);
    }, 10);
  }, []);

  return { isShow };
};

export const Mask = (props) => {
  const { onClose } = props;
  const { isShow } = useFadeIn();

  return (
    <div
      className={classnames(
        "fixed top-0 bottom-0 left-0 right-0 bg-black duration-300",
        isShow ? "opacity-80" : "opacity-0"
      )}
      onClick={() => {
        onClose();
      }}
    />
  );
};

export const InitLibrary = (props) => {
  const { initAmount, initExpired } = props;
  const { isShow } = useFadeIn();
  const [account, setAccount] = useState(
    LIBRARY_ADDRESS || "0x1168e88ffc5cec53b398b42d61885bbb"
  );
  const [amount, setAmount] = useState(initAmount || "0.001");
  const [expired, setExpired] = useState(initExpired || "1800");
  const [hash, setHash] = useState("");

  const handleCall = useCallback(async () => {
    try {
      const functionId = `${LIBRARY_ADDRESS}::${INIT_LIBRARY_FUNC_NAME}`;
      const strTypeArgs = [];
      const tyArgs = utils.tx.encodeStructTypeTags(strTypeArgs);
      const args = [];

      const scriptFunction = utils.tx.encodeScriptFunction(
        functionId,
        tyArgs,
        args
      );

      // Multiple BcsSerializers should be used in different closures, otherwise, the latter will be contaminated by the former.
      const payloadInHex = (function () {
        const se = new bcs.BcsSerializer();
        scriptFunction.serialize(se);
        return hexlify(se.getBytes());
      })();

      const txParams = {
        data: payloadInHex,
      };

      const expiredSecs = parseInt(expired, 10);
      if (expiredSecs > 0) {
        txParams.expiredSecs = expiredSecs;
      }
      const hash = await starcoinProvider
        .getSigner()
        .sendUncheckedTransaction(txParams);
      console.log({ hash });
      setHash(hash);
    } catch (e) {
      setHash(e.message || "Unkown Error");
    }
  }, [account, amount, expired]);

  return (
    <div
      className={classnames(
        "fixed top-2/4 left-2/4 -translate-x-2/4 -translate-y-2/4 rounded-2xl shadow-2xl w-3/4 p-6 bg-white duration-300",
        isShow ? "opacity-100 scale-100" : "opacity-0 scale-50"
      )}
    >
      <div className="font-bold">To</div>
      <div className="mt-2 mb-2">
        <input
          type="text"
          className="focus:outline-none rounded-xl border-2 border-slate-700 w-full p-4"
          value={account}
          onChange={(e) => {
            setAccount(e.target.value);
          }}
        />
      </div>
      <div className="font-bold">Amount of STC</div>
      <div className="mt-2 mb-2">
        <input
          type="text"
          className="focus:outline-none rounded-xl border-2 border-slate-700 w-full p-4"
          value={amount}
          onChange={(e) => {
            setAmount(e.target.value);
          }}
        />
      </div>
      <div className="font-bold">Expired</div>
      <div className="mt-2 mb-2">
        <input
          type="text"
          className="focus:outline-none rounded-xl border-2 border-slate-700 w-full p-4"
          value={expired}
          onChange={(e) => {
            setExpired(e.target.value);
          }}
        />
      </div>
      <div
        className="mt-6 p-4 flex justify-center font-bold bg-blue-900 text-white rounded-lg hover:bg-blue-700 cursor-pointer"
        onClick={handleCall}
      >
        CALL
      </div>
      {hash && (
        <div className="text-center mt-2 text-gray-500 break-all">
          Transaction: {hash}
        </div>
      )}
    </div>
  );
};

// TODO: Finish AddBook
export const AddBook = (props) => {
 const utf8Encode = new TextEncoder();
  const [name, setName] = useState("")
  const [link, setLink] = useState("")
  const [txHash, setTxHash] = useState()
  const [disabled, setDisabled] = useState(false)
  const [txStatus, setTxStatus] = useState()
  const handleCall = () => {
    setDisabled(true)
    setTxStatus("Pending...")
    const add_book = async () => {
      const tyArgs = []
        console.log(name)
        console.log(link)
//        const args = [`x\"${ name }\"`,`x\"${ link }\"`]
        const args = [name,link]

        let txHash = await executeFunction2(LIBRARY_ADDRESS, S_ADD_BOOK_FUNC_NAME, tyArgs, args)
      setTxHash(txHash)
      let timer = setInterval(async () => {
        const txnInfo = await starcoinProvider.getTransactionInfo(txHash);
        setTxStatus(txnInfo.status)
        if (txnInfo.status === "Executed") {
          setDisabled(false)
          clearInterval(timer);
        }
      }, 500);
    }
    add_book()

  }
  const { isShow } = useFadeIn();

  return (
    <div
      className={classnames(
        "fixed top-2/4 left-2/4 -translate-x-2/4 -translate-y-2/4 rounded-2xl shadow-2xl w-3/4 p-6 bg-white duration-300",
        isShow ? "opacity-100 scale-100" : "opacity-0 scale-50"
      )}
    >
      <div className="font-bold">To</div>
      <div className="mt-2 mb-2">
        <input
          type="text"
          className="focus:outline-none rounded-xl border-2 border-slate-700 w-full p-4"
          value={name}
          onChange={(e) => setName(e.target.value)}
        />
      </div>
        <div className="mt-2 mb-2">
            <input
                type="text"
                className="focus:outline-none rounded-xl border-2 border-slate-700 w-full p-4"
                value={link}
                onChange={(e) => setLink(e.target.value)}
            />
        </div>
      <div
        className="mt-6 p-4 flex justify-center font-bold bg-blue-900 text-white rounded-lg hover:bg-blue-700 cursor-pointer"
        onClick={handleCall}
        disabled={disabled}
      >
        CALL
      </div>
      {txHash && (
        <div className="text-center mt-2 text-gray-500 break-all">
          Transaction: {txHash}
        </div>
      )}
      {txStatus ? <div style={{ "textAlign": "Center" }}>{txStatus}</div> : null}
    </div>
  );
};