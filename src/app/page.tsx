import Image from "next/image";

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col gap-4 items-center justify-center">
      <Image src="/vercel.svg" alt="vercel logo" width={100} height={22.61} />
      <p>도커 테스트</p>
      <p>환경: {process.env.NODE_ENV}</p>
    </main>
  );
}
