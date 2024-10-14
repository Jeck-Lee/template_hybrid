//
//  ViewController.swift
//  template_hybrid
//
//  Created by Jeck Lee on 10/14/24.
//

import UIKit
import WebKit

/// 단일 프로세스에서 여러 웹 보기를 실행하는 데 사용하는 불투명 토큰
/// WKWebView는 각자만의 쿠키 저장소를 지님. -> 같은 processPool을 공유해야 쿠키 유지됨
/// (출처: https://twih1203.medium.com/objective-c-wkwebview-쿠키-관리하기-4b1fbb5f6b35)
fileprivate let processPool = WKProcessPool()
fileprivate let handlerName = "messageHandlers"

class ViewController: UIViewController {
	@IBOutlet var webView: WKWebView?

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		setupWebView()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		if let url = URL(string: appBaseURL) {
			webView?.load(URLRequest(url: url))
		}
	}

	private func setupWebView() {
		// 웹 보기에 대한 기본 설정 관련 설정을 관리하는 개체
		let pref = WKPreferences()
		// JavaScript가 사용자 상호 작용 없이 창을 열 수 있는지 여부
		pref.javaScriptCanOpenWindowsAutomatically = true
		
		let contentController = WKUserContentController()
		// 브릿지 함수 추가
		WebViewBridge.allCases.forEach { bridgeName in
			contentController.add(self, name: bridgeName.rawValue)
		}
		
		let configuration = WKWebViewConfiguration()
		// 웹 보기에 대한 기본 설정 관련 설정을 관리하는 개체
		configuration.preferences = pref
		// 웹 보기가 웹 콘텐츠를 렌더링하고 스크립트를 실행하는 데 사용하는 프로세스를 조정하는 개체
		configuration.processPool = processPool
		// 웹 보기가 웹 페이지의 크기를 조정할 수 있는지 여부를 결정하는 부울 값입니다.
		configuration.ignoresViewportScaleLimits = true
		// 콘텐츠가 메모리에 완전히 로드될 때까지 웹 보기에서 콘텐츠 렌더링을 억제하는지 여부를 나타내는 부울 값입니다.
		configuration.suppressesIncrementalRendering = true
		configuration.userContentController = contentController
		
		webView = WKWebView(frame: .zero, configuration: configuration)
		webView?.uiDelegate = self
		webView?.navigationDelegate = self
		
		view.addSubview(webView!)
		webView?.translatesAutoresizingMaskIntoConstraints = false
		webView?.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
		webView?.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
		webView?.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
		webView?.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
	}
}

//---------------------------------------------------------------------------------
// MARK: - WKUIDelegate
//---------------------------------------------------------------------------------
extension ViewController: WKUIDelegate {
	// 새로운 웹뷰를 만들어주는 메서드
	func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures
	) -> WKWebView? {
		/**
		 [webView]
		 - 델리게이트 메서드를 호출할 웹뷰
		 [configuration]
		 - 새로운 웹뷰를 만들 때 사용할 구성
		 [navigationAction]
		 - 새로운 웹뷰를 만들어서 호출할 때 야기할 행동
		 [windowFeatures]
		 - 웹페이지의 요구 특징
		 */
		return nil
	}
	
	// webView창이 성공적으로 닫혔음을 알려줍니다.
	func webViewDidClose(_ webView: WKWebView) {
		
	}
	
	// alert창에서 확인만 필요할 때
	func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
		let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
		let okAction = UIAlertAction(title: "확인", style: .default) { (action) in
			completionHandler()
		}
		alert.addAction(okAction)
	}
	
	// alert창에서 확인과 취소가 필요할 때
	func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
		let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
		let okAction = UIAlertAction(title: "확인", style: .default) { (action) in
			completionHandler(true)
		}
		let cancelAction = UIAlertAction(title: "취소", style: .default) { (action) in
			completionHandler(false)
		}
		alert.addAction(okAction)
		alert.addAction(cancelAction)
	}
	
	// alert창에서 text를 입력해야 할 때
	func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
		let alert = UIAlertController(title: "", message: prompt, preferredStyle: .alert)
		let okAction = UIAlertAction(title: "확인", style: .default) { (action) in
			if let text = alert.textFields?.first?.text {
				completionHandler(text)
			} else {
				completionHandler(defaultText)
			}
		}
		alert.addAction(okAction)
	}
}
//---------------------------------------------------------------------------------
// MARK: - WKNavigationDelegate
//---------------------------------------------------------------------------------
extension ViewController: WKNavigationDelegate {
	// 웹 페이지의 탐색 허용 여부를 결정
	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void ) {
		/**
		 [webView]
		 - 요구가 시작되는 것으로부터의 웹뷰
		 [navigationAction]
		 - 탐색 요청을 트리 거한 작업에 대한 세부 정보를 포함하고 있는 객체
		 - URLRequest로부터 URL을 호출할 때 해당 매개변수로 접근
		 [preferences]
		 - 새로운 웹페이지를 보여줄 때 사용하는 기본 환경설정 정보
		 [decisionHandler]
		 - 함수 타입으로 특정 인자 값을 넣어 호출을 함으로써 웹페이지의 로딩 여부를 결정하는 것입니다.
		 - 이 매개변수를 사용하면 특정 url을 들어가는 웹페이지를 차단을 할 수 있는데 그 방법은 해당 함수의 인자 값을. cancel로 바꿔서 호출하면 됩니다.
		 [만약 특정 url을 차단]
		 guard let url = navigationAction.request.url?.absoluteString else { return }
			 if url.start(with: “http”) {
			 decisionHandler(.cancel)
			 }
		 */
		
		decisionHandler(.allow)
		return
	}
	
	// 웹뷰가 메인 프레임을 위한 콘텐츠를 받기 시작할 때
	func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
	}
	
	// 웹뷰가 콘텐츠 데이터를 받아오는 것을 모두 마쳤을 때
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
	}
	
	// 콘텐츠 로딩이 실패를 했을 때 호출이 되는 메서드로 웹페이지를 불러오는 도중에 실패했을 때
	// 웹페이지 로딩되었을 때  호출되는 것이 아니라 URL이 잘못되었거나 네트워크 오류가 발생해 웹페이지 자체를 아예 불러오지 못했을 때 호출되는 메서드
	func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
	}
	
	// URL이 잘못되었거나 네트워크 오류가 발생해 웹페이지 자체를 아예 불러오지 못했을 때
	func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
	}
}
//---------------------------------------------------------------------------------
// MARK: - WKScriptMessageHandler
//---------------------------------------------------------------------------------
extension ViewController: WKScriptMessageHandler {
	// 브릿지 핸들러
	func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
		print("💠 name: \(message.name), body: \(message.body) 💠")
	}
}
